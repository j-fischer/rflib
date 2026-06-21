# RFLIB Node Logger (Lightning Web Runtime on Node.js)

The `rflib` npm package ships a server-side logger for Node.js applications that report into
Salesforce using the same buffer-and-publish model as RFLIB's Apex and LWC loggers. Log messages are
buffered per request/user and, once a configurable threshold is reached, the buffered stack is
published as an `rflib_Log_Event__e` Platform Event so it surfaces in the Ops Center dashboard and any
configured log forwarders (Slack, Teams, App Insights, OpenTelemetry, …) alongside your on-platform
logs.

Its primary documented host is **Lightning Web Runtime (LWR) on Node.js**, but the logger is
runtime-agnostic: it works in any Node.js process (Express, AWS Lambda, a plain script) because the
host supplies the Salesforce connection — the logger never authenticates on its own.

> **Replaces the Salesforce Functions logger.** Salesforce Functions reached end of life on
> 31 Jan 2025. RFLIB **10.x** is the last line that targets Functions (it reads the now-removed
> `Functions_*` Logger Settings fields). From **RFLIB 11.0.0** the logger reads the standard
> `Client_*` Logger Settings and takes an injected data adapter, as described below.

## Install

```bash
npm install rflib
# the reference adapter below uses jsforce to reach the org
npm install jsforce
```

## How it works

`createLogger(dataApi, context, loggerName, options)` returns a logger instance that owns its **own**
in-memory log stack and configuration.

- **One logger per request/user.** Because a Node/LWR server is long-running and serves many users
  concurrently, you must create a logger per request (or per authenticated user) and must **not**
  reuse a single instance across users. Each instance keeps its own stack, so one user's messages can
  never leak into another user's published Log Event — matching RFLIB's per-context convention.
- **Injected data adapter.** `dataApi` is any object exposing `query(soql)` (resolves the first
  record) and `create({ type, fields })` (publishes a Platform Event). The logger reads its settings
  via `query` and publishes via `create`. You typically adapt a jsforce `Connection` (see below).
- **Configuration** comes from `rflib_Logger_Settings__c` (a Hierarchy custom setting), reusing the
  existing client-logging fields. The logger resolves the hierarchy the way Apex `getInstance()`
  does — the most specific row wins — using the ids on the context: pass `context.user.id` (and
  optionally `context.user.profileId`) to honor user/profile-level overrides; with only
  `context.org.id` it uses org defaults.

    | Logger config     | Logger Settings field         |
    | ----------------- | ----------------------------- |
    | `computeLogLevel` | `Client_Console_Log_Level__c` |
    | `serverLogLevel`  | `Client_Server_Log_Level__c`  |
    | `stackSize`       | `Client_Log_Size__c`          |

    `computeLogLevel` controls what is echoed to the compute log (stdout / `console`); `serverLogLevel`
    controls when the buffered stack is published as a Platform Event (minimum effective level `INFO`).

- **Platform info.** Each published event includes a `Platform_Info__c` payload. By default the logger
  collects Node runtime telemetry (process memory, cpu, uptime, version) under a `node` key, which the
  Apex `rflib_PlatformInfoParser` flattens to `rflib.platform.node.*`. Provide
  `options.platformInfoProvider` to override or extend it (e.g. add the LWR route, SSR flag, or request
  duration).

## Connecting to the org (jsforce + JWT integration user)

Authentication stays out of the logger. The recommended pattern for a server is the OAuth 2.0 JWT
Bearer flow with a single **integration user** and a Connected App, so log events are published with a
stable identity regardless of which end user triggered the request.

```js
const jsforce = require('jsforce');

// Authenticate once per process and reuse the connection.
async function createConnection() {
    const conn = new jsforce.Connection({ loginUrl: process.env.SF_LOGIN_URL });
    await conn.authorize({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: buildSignedJwt() // sign with your Connected App's certificate
    });
    return conn;
}

// Adapt a jsforce Connection to the minimal { query, create } shape the logger expects.
// Return the full `records` array so the logger can resolve the Logger Settings hierarchy
// (org / profile / user) — returning a single record limits it to org-level defaults.
function toDataApi(conn) {
    return {
        query: async (soql) => {
            const result = await conn.query(soql);
            return result.records;
        },
        create: ({ type, fields }) => conn.sobject(type).create(fields)
    };
}
```

## Using it in an LWR `getServerData` hook

Create the logger inside the per-request server hook, keyed to the authenticated user, so the stack is
isolated per request.

```js
const { createLogger } = require('rflib');

export async function getServerData() {
    const conn = await getConnectionForThisProcess();
    const user = this.request.user; // however your LWR app resolves the authenticated user

    const logger = createLogger(
        toDataApi(conn),
        {
            id: this.request.id, // recorded as Request_Id__c
            org: { id: user.organizationId }, // org-default Logger Settings row
            user: { id: user.userId, profileId: user.profileId } // resolves user/profile-level overrides
        },
        'home-route'
    );

    try {
        logger.info('Rendering home route for user {0}', user.userId);
        const data = await loadHomeData(conn);
        return { data };
    } catch (err) {
        logger.fatal('Failed to render home route: {0}', err.message);
        throw err;
    }
}
```

The same pattern works in an Express handler or a Lambda — create one logger per invocation/request.

## Application events

`createApplicationEventLogger(dataApi, context, options)` publishes
`rflib_Application_Event_Occurred_Event__e` events for business-level auditing:

```js
const { createApplicationEventLogger } = require('rflib');

const appEvents = createApplicationEventLogger(toDataApi(conn), context);
appEvents.logApplicationEvent('checkout-completed', orderId, { total: 49.99 });
```

## Options

| Option                 | Default                | Description                                                              |
| ---------------------- | ---------------------- | ------------------------------------------------------------------------ |
| `computeLogger`        | `console`              | Console-like sink for the compute (stdout) stream.                       |
| `shouldClearLogs`      | `false`                | Clears this instance's log stack on creation.                            |
| `platformInfoProvider` | Node runtime telemetry | Returns the object stored in `Platform_Info__c` when an event publishes. |
