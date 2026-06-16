# Logging to OpenTelemetry (OTLP/HTTP)

RFLIB can forward log events to any [OpenTelemetry Protocol (OTLP)](https://opentelemetry.io/docs/specs/otlp/) logs endpoint that accepts **OTLP/HTTP JSON**. The **one** `Send_Log_Event_to_OTel` action (`rflib_OpenTelemetryLogAction`) emits OTLP/HTTP JSON (`Content-Type: application/json`) and works with:

- **AWS CloudWatch Logs** native OTLP endpoint — accepts OTLP/HTTP JSON; a serverless, Lambda-free alternative to the API Gateway + Lambda setup in [the CloudWatch wiki](https://github.com/j-fischer/rflib/wiki/Logging-to-AWS-CloudWatch).
- **OpenTelemetry Collectors** and any backend reachable through one (Grafana/Tempo/Loki, Datadog, Honeycomb, New Relic, Splunk, ...).
- **Azure Monitor** — only **via an OpenTelemetry Collector** in between (see the Azure recipe below). Azure Monitor's _native_ OTLP ingestion requires OTLP/HTTP **protobuf**, which this action does not emit. For direct Azure ingestion without a collector, use the **App Insights action** instead — see [`../azure/README.md`](../azure/README.md).

> **Encoding note:** this action emits OTLP/HTTP **JSON**, not protobuf (Apex has no practical protobuf serializer). Any backend you target must accept the JSON encoding (or sit behind a collector that does).

The destination URL and any backend-specific headers (API keys, log-group names, etc.) live entirely on the `RFLIB_OTEL_LOGS` Named Credential, so switching or adding a backend never requires a code change.

## How it works

Each batch of log events becomes a single OTLP `resourceLogs` payload. Every event is one `logRecord`:

- `timeUnixNano` / `observedTimeUnixNano` — the event's created timestamp in nanoseconds
- `severityNumber` / `severityText` — the RFLIB level mapped to the OTel severity scale (see below)
- `body.stringValue` — the log messages (front-truncated to keep the most recent content)
- `attributes` — `rflib.context`, `rflib.request_id`, `rflib.source_system_id`, `rflib.log_source`, `rflib.stacktrace`, `enduser.id`, plus the event's `Platform_Info__c` flattened into typed attributes (`rflib.apex.*`, `rflib.browser.*`, `user_agent.original`)

Resource attributes identify the source: `service.name` (the `OTel_Service_Name` Global Setting, default `salesforce-rflib`), `service.instance.id` (the Org Id), and `telemetry.sdk.name`/`telemetry.sdk.language`/`telemetry.sdk.version` (`rflib-apex` / `apex` / the package version).

> RFLIB's request id is carried as the `rflib.request_id` attribute rather than the OTLP `traceId`/`spanId` fields, because those require 16-/8-byte hex identifiers that the Salesforce request id does not satisfy. RFLIB forwards fire-and-forget and does not implement OTLP throttling/`Retry-After` backoff; rejected or failed sends are recorded as `rflib-otel-log-event-failed` application events.

Events are sent in callouts of up to 100 records. A `200` with no `partialSuccess.rejectedLogRecords` is treated as success; anything else is recorded as an `rflib-otel-log-event-failed` application event with the response body for diagnosis. RFLIB does not retry (fire-and-forget).

### Severity mapping

| RFLIB level | OTel `severityNumber` | `severityText` |
| ----------- | --------------------- | -------------- |
| TRACE       | 1                     | TRACE          |
| DEBUG       | 5                     | DEBUG          |
| INFO        | 9                     | INFO           |
| WARN        | 13                    | WARN           |
| ERROR       | 17                    | ERROR          |
| FATAL       | 21                    | FATAL          |

## Common Salesforce setup

1. Install RFLIB **10.4.0** or later.
2. Create a Named Credential named exactly `RFLIB_OTEL_LOGS` whose **URL is the full OTLP logs endpoint** (including the `/v1/logs` path or the backend's equivalent). Configure authentication and any required custom headers per the recipe below.
3. (Optional) Create an RFLIB Global Setting `OTel_Service_Name` to override the default `service.name` of `salesforce-rflib`.
4. In **Logger Settings**, set **OTel Log Level** to `ERROR` (or higher-verbosity as needed). It must be at or above the Log Event Reporting Level. Default is `NONE` (disabled).
5. Validate with anonymous Apex:

    ```apex
    rflib_Logger logger = rflib_LoggerUtil.getFactory().createLogger('OTelTest');
    logger.setReportingLogLevel(rflib_LogLevel.ERROR);
    logger.error('RFLIB → OTLP connectivity test');
    ```

    Failures appear as `rflib-otel-log-event-failed` application events.

## Backend recipes

### Azure Monitor (preview) — requires an OpenTelemetry Collector

Azure Monitor's native OTLP ingestion accepts only OTLP/HTTP **protobuf**, so RFLIB cannot post to the DCR endpoint directly (it emits JSON). Two options:

- **Recommended for Azure:** skip OTLP and use the **App Insights action** (`RFLIB_APP_INSIGHTS`), which ingests directly over JSON. See [`../azure/README.md`](../azure/README.md).
- **If you specifically want the OTLP pipeline:** run an **OpenTelemetry Collector** that accepts OTLP/HTTP JSON from Salesforce and re-exports OTLP/HTTP **protobuf** to Azure Monitor. Point `RFLIB_OTEL_LOGS` at the **collector's** `/v1/logs` (not the DCR), and configure the collector with the Azure auth + DCR endpoint per Microsoft's collector docs. Flow: `Salesforce → (OTLP/JSON) → Collector → (OTLP/protobuf) → Azure Monitor`.

### AWS CloudWatch Logs (Lambda-free)

CloudWatch Logs exposes a native OTLP endpoint, so you can drop the API Gateway + Lambda pipeline entirely.

- External Credential: **AWS Signature Version 4** (the same pattern as the existing CloudWatch wiki), service `logs`, with an IAM identity allowed to `logs:PutLogEvents`.
- Named Credential URL: `https://logs.<region>.amazonaws.com/v1/logs`
- Add **custom headers** on the Named Credential:
    - `x-aws-log-group: <your-log-group>`
    - `x-aws-log-stream: <your-log-stream>`

CloudWatch also reports dropped records via `partialSuccess.rejectedLogRecords`, which RFLIB surfaces as an application event.

### OpenTelemetry Collector / other vendors

- Named Credential URL: your collector or vendor endpoint ending in `/v1/logs`.
- Add whatever auth the backend expects (e.g. an `Authorization` or API-key custom header) on the Named Credential.

## Troubleshooting

| Symptom                                    | Likely cause                                                                                                                                  |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `rflib-otel-log-event-failed` with 401/403 | Wrong/missing auth on the Named Credential, or the flow's running user lacks External Credential principal access.                            |
| 200 but recorded as failure                | `partialSuccess.rejectedLogRecords > 0` — inspect the app event body for the per-record reasons (e.g. timestamps too old/new for CloudWatch). |
| Nothing arrives, no app events             | `OTel_Log_Level__c` is `NONE` or below the Log Event Reporting Level.                                                                         |
| Records rejected as "too old" (CloudWatch) | CloudWatch rejects events older than 14 days / newer than 2 hours.                                                                            |
