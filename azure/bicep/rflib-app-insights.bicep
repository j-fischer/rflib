// Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DAMAGES ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---------------------------------------------------------------------------------------------
// Provisions a workspace-based Azure Application Insights resource for receiving RFLIB log events.
//
// Cost control: the only ongoing charge is Log Analytics ingestion (pay-per-GB). A daily ingestion
// cap and a short retention window keep an idle deployment effectively free. Tune dailyCapGb and
// retentionInDays for your volume. Local (instrumentation-key) auth is disabled by default so the
// resource only accepts Microsoft Entra ID authenticated ingestion.
//
// Deploy:
//   az deployment group create -g <resource-group> -f rflib-app-insights.bicep
// ---------------------------------------------------------------------------------------------

@description('Prefix used for the created resource names.')
param namePrefix string = 'rflib'

@description('Azure region for the resources.')
param location string = resourceGroup().location

@description('Log Analytics data retention in days (30 days is included at no extra cost).')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB. Caps cost by dropping data once the cap is hit for the day.')
param dailyCapGb int = 1

@description('Disable local (instrumentation key) authentication so only Microsoft Entra ID auth is accepted.')
param disableLocalAuth bool = true

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${namePrefix}-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyCapGb
    }
    features: {
      disableLocalAuth: disableLocalAuth
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${namePrefix}-appinsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    IngestionMode: 'LogAnalytics'
    DisableLocalAuth: disableLocalAuth
    RetentionInDays: retentionInDays
  }
}

@description('The Application Insights resource ID. Use as the scope for the Monitoring Metrics Publisher role assignment.')
output appInsightsResourceId string = appInsights.id

@description('The connection string. Contains both the InstrumentationKey and the IngestionEndpoint.')
output connectionString string = appInsights.properties.ConnectionString

@description('The instrumentation key. Store this as the App_Insights_Instrumentation_Key RFLIB Global Setting.')
output instrumentationKey string = appInsights.properties.InstrumentationKey
