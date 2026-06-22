# Logging to Azure Application Insights

RFLIB can forward log events to [Azure Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview) so that Salesforce logs are searchable alongside the rest of your Azure observability data. The integration sends telemetry **directly** from Apex to the Application Insights ingestion endpoint — there is no Azure Function, App Gateway, or other compute to deploy or pay for. The only ongoing Azure charge is Log Analytics ingestion (pay-per-GB), which a daily cap keeps under control.

There are two ways to land RFLIB logs in Azure:

| Route                                                 | Action                                                          | Status  | Where logs land             |
| ----------------------------------------------------- | --------------------------------------------------------------- | ------- | --------------------------- |
| **A. App Insights direct ingestion** (recommended)    | `Send_Log_Event_to_App_Insights` (`rflib_AppInsightsLogAction`) | GA      | App Insights `traces` table |
| **B. Azure Monitor OTLP ingestion** (via a Collector) | `Send_Log_Event_to_OTel` (`rflib_OpenTelemetryLogAction`)       | Preview | Log Analytics (OTel schema) |

Route A is documented in full below. Route B is summarized at the end and shares the generic OpenTelemetry setup in [`../otel/README.md`](../otel/README.md).

## Architecture

```
rflib_Log_Event__e  ──►  RFLIB Log Event Handler (Flow)  ──►  rflib_AppInsightsLogAction
                                                                    │  POST (NDJSON envelopes)
                                                                    ▼
                                          Named Credential RFLIB_APP_INSIGHTS (Entra OAuth)
                                                                    │
                                                                    ▼
                                       Application Insights ingestion endpoint (v2.1/track)
                                                                    │
                                                                    ▼
                                              App Insights `traces` (Log Analytics workspace)
```

Each log event becomes a `Microsoft.ApplicationInsights.Message` envelope. The RFLIB log level maps to the App Insights severity scale, and the event's `Platform_Info__c` is flattened into individually queryable custom properties (e.g. `rflib.apex.cpu_time`, `user_agent.original`).

## Cost expectations

- **Compute:** none. Ingestion is a direct HTTPS call from Salesforce.
- **Ingestion:** Log Analytics charges per GB ingested. The provided Bicep template sets a **1 GB/day cap** and **30-day retention** (retention up to 31 days is included at no charge).
- Keep the `App_Insights_Log_Level__c` threshold at `ERROR` or `WARN` in production to limit volume. `DEBUG`/`TRACE` can generate significant data.

## Prerequisites

- An Azure subscription and permission to create resources and Entra app registrations.
- The Azure CLI (`az`) — the Azure Cloud Shell has everything pre-installed.
- RFLIB **11.0.0** or later installed in your Salesforce org.

## Step 1 — Deploy the Application Insights resource

```bash
az group create -n rflib-logging -l eastus
az deployment group create -g rflib-logging -f azure/bicep/rflib-app-insights.bicep
```

Record the deployment outputs:

- `appInsightsResourceId` — used for the role assignment in Step 2.
- `instrumentationKey` — used for the Global Setting in Step 5.
- `connectionString` — contains the `IngestionEndpoint` (e.g. `https://eastus-8.in.applicationinsights.azure.com/`) used for the Named Credential in Step 4.

## Step 2 — Create the Entra app registration

```bash
bash azure/scripts/setup-entra-app.sh <appInsightsResourceId>
```

The script creates an app registration + service principal, generates a client secret, assigns the least-privilege **Monitoring Metrics Publisher** role on the resource, and prints the values you need for Salesforce: **Tenant ID, Client ID, Client Secret, Token Endpoint, OAuth Scope**.

> Role assignments can take a few minutes to propagate. If your first callout returns 403, wait and retry.

## Step 3 — Create the External Credential

In **Setup → Security → Named Credentials → External Credentials**, create one named `RFLIB_APP_INSIGHTS_AUTH`:

- **Authentication Protocol:** OAuth 2.0
- **Authentication Flow Type:** Client Credentials with Client Secret
- **Identity Provider URL / Token Endpoint:** `https://login.microsoftonline.com/<tenantId>/oauth2/v2.0/token`
- **Scope:** `https://monitor.azure.com//.default` (the double slash is intentional — the audience is `https://monitor.azure.com/`)
- Add a **Principal** (Named Principal) and enter the **Client ID** and **Client Secret** from Step 2.

## Step 4 — Create the Named Credential

In **Setup → Named Credentials**, create one named exactly `RFLIB_APP_INSIGHTS`:

- **URL:** the `IngestionEndpoint` from the connection string (e.g. `https://eastus-8.in.applicationinsights.azure.com`)
- **External Credential:** `RFLIB_APP_INSIGHTS_AUTH`
- **Generate Authorization Header:** enabled

> **Most common setup failure:** the Log Event Handler flow runs as the **Automated Process / Default Workflow user**, not you. That user must have **principal access** to the External Credential, otherwise callouts fail with 401 and are recorded as `rflib-app-insights-log-event-failed` application events. Create a Permission Set that grants access to the `RFLIB_APP_INSIGHTS_AUTH` principal and assign it to the user the flow runs as.

## Step 5 — Configure the instrumentation key

Create an RFLIB Global Setting so each telemetry envelope is routed to your resource. In **Setup → Custom Metadata Types → RFLIB Global Setting → Manage Records**, create a record:

- **Name / DeveloperName:** `App_Insights_Instrumentation_Key`
- **Value:** the `instrumentationKey` from Step 1

## Step 6 — Set the log level

In **Setup → Custom Settings → Logger Settings → Manage**, set **App Insights Log Level** to `ERROR` (or `WARN`/`INFO`/...). The level must be the same or higher than the **Log Event Reporting Level**, otherwise the events are never published in the first place. The default is `NONE`, which disables forwarding.

## Step 7 — Validate

Run anonymous Apex to emit an error log event:

```apex
rflib_Logger logger = rflib_LoggerUtil.getFactory().createLogger('AppInsightsTest');
logger.setReportingLogLevel(rflib_LogLevel.ERROR);
logger.error('RFLIB → Application Insights connectivity test');
```

After 1–3 minutes, query in the Application Insights **Logs** blade:

```kusto
traces
| where message has "connectivity test"
| project timestamp, message, severityLevel, customDimensions
| order by timestamp desc
```

The `customDimensions` will include `Context`, `RequestId`, `LogLevel`, and the flattened `rflib.apex.*` platform-info values.

## Troubleshooting

| Symptom                                                   | Likely cause                                                                                                                                                                          |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rflib-app-insights-log-event-failed` app events with 401 | The flow's running user lacks principal access to `RFLIB_APP_INSIGHTS_AUTH` (see Step 4 note).                                                                                        |
| 403 on first callouts                                     | Role assignment still propagating, or the wrong scope.                                                                                                                                |
| HTTP 206 recorded as failure                              | Partial success — some items were rejected. The app event body contains `itemsReceived/itemsAccepted/errors[]`. RFLIB does not retry.                                                 |
| Nothing arrives, no app events                            | `App_Insights_Log_Level__c` is `NONE` or below the Log Event Reporting Level; or the `App_Insights_Instrumentation_Key` Global Setting is missing (forwarding is skipped when blank). |
| Daily data missing                                        | The Log Analytics daily cap was reached — raise `dailyCapGb` or the log-level threshold.                                                                                              |

## Route B — Azure Monitor OTLP ingestion (preview, via a Collector)

If you prefer the vendor-neutral OpenTelemetry pipeline, note an important constraint: Azure Monitor's native OTLP ingestion accepts only OTLP/HTTP **protobuf**, while RFLIB's `rflib_OpenTelemetryLogAction` emits OTLP/HTTP **JSON** (Apex has no practical protobuf serializer). RFLIB therefore **cannot post to the Azure DCR endpoint directly**.

To use this route, run an **OpenTelemetry Collector** between Salesforce and Azure Monitor:

1. Create an Application Insights resource with **OTLP support: On** (auto-provisions the Data Collection Endpoint/Rule) and assign **Monitoring Metrics Publisher** on the **DCR** to the app registration.
2. Deploy an OpenTelemetry Collector that accepts OTLP/HTTP JSON and exports OTLP/HTTP **protobuf** to the Azure DCR endpoint (`https://<dce>.<region>.ingest.monitor.azure.com/dataCollectionRules/<dcr-immutable-id>/streams/Microsoft-OTLP-Logs/otlp/v1/logs`) using the Azure auth extension.
3. Point the `RFLIB_OTEL_LOGS` Named Credential at the **collector's** `/v1/logs` endpoint and set `OTel_Log_Level__c` in the Logger Settings.

Flow: `Salesforce → (OTLP/JSON) → Collector → (OTLP/protobuf) → Azure Monitor`. Logs land in Log Analytics using the OpenTelemetry schema. See [`../otel/README.md`](../otel/README.md) for the collector recipe and other OTLP backends.

**For direct Azure ingestion without a collector, use Route A (App Insights direct ingestion) above** — it is the recommended path for most Azure users. This OTLP ingestion path is also in **public preview** at the time of writing.
