#!/usr/bin/env bash
# Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the conditions of the BSD 3-Clause License are met. See the project LICENSE.
#
# ---------------------------------------------------------------------------------------------
# Creates the Microsoft Entra ID app registration that Salesforce uses to authenticate to Azure
# Application Insights (or Azure Monitor OTLP) ingestion, and grants it the least-privilege
# "Monitoring Metrics Publisher" role on the target resource.
#
# Entra objects cannot be created with Bicep/ARM, so this is a companion script. Run it in the
# Azure Cloud Shell (bash) or anywhere the Azure CLI is logged in (az login).
#
# Usage:
#   ./setup-entra-app.sh <app-insights-resource-id> [app-display-name]
#
# The <app-insights-resource-id> is the appInsightsResourceId output of rflib-app-insights.bicep.
# For the Azure Monitor native OTLP route, pass the Data Collection Rule (DCR) resource ID instead.
# ---------------------------------------------------------------------------------------------

set -euo pipefail

RESOURCE_ID="${1:?Provide the Application Insights (or DCR) resource ID as the first argument}"
APP_NAME="${2:-rflib-log-forwarder}"
ROLE="Monitoring Metrics Publisher"

echo "Creating Entra app registration '${APP_NAME}'..."
APP_ID=$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)
echo "  Application (client) ID: ${APP_ID}"

echo "Creating service principal..."
# Capture the service principal object id for a replication-safe role assignment below.
SP_OBJECT_ID=$(az ad sp create --id "${APP_ID}" --query id -o tsv)

echo "Generating a client secret (valid 1 year)..."
# For higher security prefer a certificate credential instead of a secret:
#   az ad app credential reset --id "${APP_ID}" --cert @cert.pem --append
CLIENT_SECRET=$(az ad app credential reset --id "${APP_ID}" --years 1 --query password -o tsv)

TENANT_ID=$(az account show --query tenantId -o tsv)

# Print the credentials BEFORE the role assignment. The client secret is shown only once, and the
# role assignment can transiently fail on a brand-new service principal due to Entra replication
# delay; printing first ensures a failure there never leaves the operator without usable credentials.
cat <<EOF

=====================================================================================
RFLIB Azure ingestion - Salesforce configuration values
=====================================================================================
Tenant ID (Directory ID):  ${TENANT_ID}
Client ID (Application ID): ${APP_ID}
Client Secret:             ${CLIENT_SECRET}   <-- store securely; shown only once
Token Endpoint:            https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token
OAuth Scope:               https://monitor.azure.com//.default

Use these in the Salesforce External Credential (Client Credentials with Client Secret).
Retrieve the IngestionEndpoint and InstrumentationKey from the Bicep deployment outputs
(or the resource's Connection String) for the Named Credential and Global Setting.
=====================================================================================
EOF

echo "Assigning '${ROLE}' on the target resource (role propagation can take a few minutes)..."
# Assign by the service principal object id with an explicit principal type. This avoids the Graph
# name-resolution lookup that can fail for a just-created principal during Entra replication.
# See: https://learn.microsoft.com/azure/role-based-access-control/role-assignments-cli#assign-a-role-for-a-new-service-principal-at-a-resource-group-scope
az role assignment create \
  --assignee-object-id "${SP_OBJECT_ID}" \
  --assignee-principal-type ServicePrincipal \
  --role "${ROLE}" \
  --scope "${RESOURCE_ID}" >/dev/null

echo "Role '${ROLE}' assigned to the service principal on the target resource."
