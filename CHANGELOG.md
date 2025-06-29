### RFLIB-PHAROS 1.0.0

Package ID: 04tKY000000xhxmYAA
Package Alias: RFLIB@1.0.0-5
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xhxmYAA

- [PR #114](https://github.com/j-fischer/rflib/pull/114) Initial version of the Pharos integration, which is fully configurable to accommodate future Pharos versions without requiring code changes. See [https://pharos.ai/](https://pharos.ai/) and the [Getting Started with Pharos Integration](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Pharos-Integration) Wiki page for more information.

### RFLIB 10.0.0

Package ID: 04tKY000000xdPOYAY
Package Alias: RFLIB@10.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xdPOYAY

- [PR #116](https://github.com/j-fischer/rflib/pull/116) Introduced several enhancements to the Log Monitor, including field visibility settings, improved JSON content display, message highlighting by log level, and a full-screen viewing mode. These improvements collectively make log events easier to read, navigate, and analyze through better visual organization and user interface guidance. [Feature Request #113](https://github.com/j-fischer/rflib/issues/113)
- [PR #114](https://github.com/j-fischer/rflib/pull/114) Enhanced Log Event by adding stacktrace support and improved log source tracking (Apex/Flow/LWC). Stacktraces are now visibile in the Log Event Viewer under a dedicated tab.

### RFLIB 9.4.0

Package ID: 04tKY000000xX6HYAU
Package Alias: RFLIB@9.4.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xX6HYAU

- [PR #112](https://github.com/j-fischer/rflib/pull/112) Added masking capability to the Application Event Service for sensitive information in the `Additional_Details__c` field, utilizing the same masking rules as the Logger framework. Added new Global Setting called 'App_Event_Masking_Enabled' to control whether masking is applied to Application Events (disabled by default). [Feature Request #111](https://github.com/j-fischer/rflib/issues/111)

### RFLIB 9.3.0

Package ID: 04tKY000000xMlyYAE
Package Alias: RFLIB@9.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xMlyYAE

- [PR #109](https://github.com/j-fischer/rflib/pull/109) Added new capability to filter the records when exporting them from the Permission Explorer UI to a CSV file. [Feature Request #107](https://github.com/j-fischer/rflib/issues/107)
- [PR #108](https://github.com/j-fischer/rflib/pull/108) Introducing a flexible field mapping utility for Salesforce that allows dynamic field mapping between SObjects using custom metadata rules. The implementation supports both direct field mapping and formula-based transformations.
- Fixed issue in Custom Settings Editor displaying "undefined" as a value when the input field should be blank.

### RFLIB 9.2.0

Package ID: 04tKY0000011PSKYA2
Package Alias: RFLIB@9.2.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY0000011PSKYA2

- [PR #104](https://github.com/j-fischer/rflib/pull/104) Added new capabilities for Big Object management, including record counting, monitoring, and cleanup. Introduced the Big Object Archive Cleanup framework with dedicated cleaners for Log and Application Event Archives. Enhanced the Management Dashboard with real-time Big Object statistics and improved scheduled job management.
- [PR #105](https://github.com/j-fischer/rflib/pull/105) Added "View All Fields" permission visibility to the Permissions Explorer UI, enabling admins to audit this critical permission across profiles, permission sets, and permission set groups. Enhanced CSV exports to include "View All Fields" data. Improved the Permissions Explorer table to clearly display "View All Fields" status alongside other object permissions. Upgraded API version to 63.0.

### RFLIB 9.1.0

Package ID: 04tKY0000011MQLYA2
Package Alias: RFLIB@9.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY0000011MQLYA2

- [PR #103](https://github.com/j-fischer/rflib/pull/103) Adoption of a SOQL library to standardize and improve our query construction across the codebase. The library provides a type-safe, fluent interface for building SOQL queries, reducing the risk of runtime errors and improving code maintainability.
- [PR #102](https://github.com/j-fischer/rflib/pull/102) Improved the logic for the cleanup of archived log records to ensure retention for at least a specified number of days, with the default being 180 days.
- Fixed bug that prevented the retrieval of Apex permissions in larger orgs from succeeding.

### RFLIB 9.0.1

Package ID: 04tKY0000011MDJYA2
Package Alias: RFLIB@9.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY0000011MDJYA2

- [Issue #101] (https://github.com/j-fischer/rflib/issues/101) Fixed regression introduced in version 8.0 that prevented the page navigation from switching pages.
- Org Limit Stat Component: Fixed progressbar not displaying the proper state based on the limits retrieved from the server. Also improved UI.

### RFLIB 9.0.0

Package ID: 04tKY000000xD5aYAE
Package Alias: RFLIB@9.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xD5aYAE

- [PR #100](https://github.com/j-fischer/rflib/pull/100) Fixed issues with Log Monitor's empAPI connection handling ([Issue 99](https://github.com/j-fischer/rflib/issues/99)).
- Added new Logger Setting Apex Contects to Monitor which allows for a comma sparated list of context names to be provided that will always publish log messages of INFO level or higher.

### RFLIB 8.1.0

Package ID: 04tKY000000xBvXYAU
Package Alias: RFLIB@8.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xBvXYAU

- [PR #98](https://github.com/j-fischer/rflib/pull/98) Eliminated extra blank tab when downloading ApexLog file. (Thank you, [Jonathan Gillespie](https://github.com/jongpie) for the PR)
- Added label to download button indicating how many ApexLog files are available.
- Improved JS logger to be smarter about the handling of log arguments for messages. It now use `JSON.stringify()` for any object and array type automatically.

### RFLIB 8.0.0

Package ID: 04tKY000000xBemYAE
Package Alias: RFLIB@8.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xBemYAE

- [PR #93](https://github.com/j-fischer/rflib/pull/93) Added new search box for Request ID and more dynamic UI for search fields in Log Monitor.
- [PR #94](https://github.com/j-fischer/rflib/pull/94) Enhanced RFLIB's DefaultLogger with advanced log aggregation, integrating logging with application events for improved observability and actionability. Logs meeting the configured log level are converted into Application Events, enabling traceability, diagnostics, and actionable insights via the Application Events Dashboard, while ensuring efficient batch processing and compliance with platform limits.
- [PR #95](https://github.com/j-fischer/rflib/pull/95) Added button allowing users to download Apex Debug Logs directly from the Monitor page. Only debug logs matching the Request Id of the Log Event will be offered for download if available.
- [PR #96](https://github.com/j-fischer/rflib/pull/96) Added new Apex Job Scheduler LWC component enables management of scheduled Apex jobs from App pages. Added the component to the Management Console to manage RFLIB Application Event Archiver job.
- [PR #97](https://github.com/j-fischer/rflib/pull/97) Introducing a new Development Mode feature that adjusts the logging behavior of RFLIB's internal UI components, specifically those used in the Ops Center. The feature is controlled via a new global configuration setting, RFLIB_Development_Mode_Enabled.
- Upgraded API version (`<apiVersion>`) to v62.0

### RFLIB 7.4.1

Package ID: 04tKY000000xAFfYAM
Package Alias: RFLIB@7.4.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xAFfYAM

- Custom Settings Editor: Improved error messages to be displayed in toast message popup.

### RFLIB-TF 3.0.2

Package ID: 04tKY000000xAF1YAM
Package Alias: RFLIB-TF@3.0.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xAF1YAM

- Retryable Actions: Updated page layout added missing Active field and changed order of fields.

### RFLIB 7.4.0

Package ID: 04tKY000000xAEwYAM
Package Alias: RFLIB@7.4.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xAEwYAM

- [PR #92](https://github.com/j-fischer/rflib/pull/92) Added tab for managing Custom Settings to Ops Center using a new generic Custom Settings component that allows to manage any Custom Settings object on a Lightning Page.

### RFLIB 7.3.0

Package ID: 04tKY000000xACgYAM
Package Alias: RFLIB@7.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xACgYAM

- [PR #91](https://github.com/j-fischer/rflib/pull/91) Created `LogFailure` method for `rflib_OmniStudioRemoteActions` class that should be used when dealing with try-catch blocks in Integration Procedures.
- Added new Apex Cursor Governor Limits to the Platform Info section of the log.
- Replaced Org Limit stat for Function API calls with Mass Email limit since SF Functions are EOL.

### RFLIB 7.2.0

Package ID: 04tKY000000xABsYAM
Package Alias: RFLIB@7.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xABsYAM

- [PR #89](https://github.com/j-fischer/rflib/pull/89) Added new configuration setting and invocable action to sent RFLIB Log Events to remote systems via HTTP Callouts. Configure the `HTTP Callout Log Level` in `Logger Settings` to enable the feature.
- [PR #90](https://github.com/j-fischer/rflib/pull/90) Added the `rflib_OmniStudioRemoteActions` to the package. You can now create `Log Events` or `Application Events` from OmniStudio components. Thanks to [Jonathan Gillespie](https://github.com/jongpie) for submitting the PR after he added the same functionality to [Nebula Logger](https://github.com/jongpie/NebulaLogger).
- Deprecated `Logger Settings` for Salesforce Functions as the feature has been end-of-lived (EOL) and is no longer available.

### RFLIB 7.1.0

Package ID: 04tKY000000xA5UYAU
Package Alias: RFLIB@7.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xA5UYAU

- [PR #88](https://github.com/j-fischer/rflib/pull/88) Added new Global Setting called Trace_ID_Value_Format which allows for the setting of two new Trace ID value formats: SF Request ID only or current user's record ID (either 15 or 18 char) + SF Request ID.

### RFLIB 7.0.0

Package ID: 04tKY000000xA5KYAU
Package Alias: RFLIB@7.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKY000000xA5KYAU

- [PR #87](https://github.com/j-fischer/rflib/pull/87) Introduced recently added Apex Database.Cursor (beta) functionality to query large number of results in Permission Explorer. This will eventually replace the REST API based approach.

### RFLIB 6.6.0

Package ID: 04t3h0000046NG9AAM
Package Alias: RFLIB@6.6.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h0000046NG9AAM

- [PR #85](https://github.com/j-fischer/rflib/pull/85) EndpointMocker: Added ability to mock requests when using the rflib_HttpRequest class for any outbound HTTP requests. This can help with integration development while the actual endpoint is not available yet. It can also be used in training or development environments where integration is generally not available.

### RFLIB 6.5.1

Package ID: 04t3h000004pOzYAAU
Package Alias: RFLIB@6.5.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOzYAAU

- Application Events: Changed logging level of DefaultApplicationEventLogger methods to DEBUG insteadl of INFO

### RFLIB 6.5.0

Package ID: 04t3h000004pOyuAAE
Package Alias: RFLIB@6.5.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOyuAAE

- [PR #84](https://github.com/j-fischer/rflib/pull/84) PermissionExplorer: Added support for viewing Apex Class and Page permissions

### RFLIB 6.4.0

Package ID: 04t3h000004pOv7AAE
Package Alias: RFLIB@6.4.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOv7AAE

- Permission Explorer: Added two new modes to query Permission Set Groups specifically and added filter to exclude Permission Set Groups when looking up Permission Sets only.
- Permission Explorer: Improved handling of error messages when retrieving permissions from the controller.

### RFLIB-TF 3.0.1

Package ID: 04t3h000004pOuxAAE
Package Alias: RFLIB-TF@3.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOuxAAE

- Trigger Framework: Refactored handling of Feature Switches to invert behaviour so that they don't need to be configured. CHANGED NAME OF FEATURE SWITCHES FOR TRIGGERS AND RETRYABLE ACTION. Renamed the Feature Switches used from All_Triggers to rflib_Disable_All_Triggers and from All_Retryable_Actions to flib_Disable_All_Retryable_Actions. The old values will not be considered anymore.
  IMPORTANT: THIS CHANGE BREAKS BACKWARDS COMPATIBILITY IF THOSE TRIGGER SWITCHES ARE USED.

### RFLIB 6.3.1

Package ID: 04t3h000004pOusAAE
Package Alias: RFLIB@6.3.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOusAAE

- Removed Global Setting CMT record Archive Log Query Limit, which was missed in the 6.3.0 release.

### RFLIB 6.3.0

Package ID: 04t3h000004pOuTAAU
Package Alias: RFLIB@6.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOuTAAU

- [PR #81](https://github.com/j-fischer/rflib/pull/81) Added new Global Setting config value to choose whether to use the Org Wide Email Address for sending out notifications or not. This allows orgs to take advantage of the new configuration setting to select the workflow user for record triggered flows. See https://help.salesforce.com/s/articleView?id=release-notes.rn_automate_flow_builder_run_event_triggered_flows_as_workflow_user.htm&release=248&type=5
- Log Monitor: Fixed bug where the query limit message would not be displayed when viewing the Log Archive.
- Removed all Global Setting CMT records and aligned their validation rules according to the documentation. (Update: Missed Archive Log Query Limit)

### RFLIB 6.2.0

Package ID: 04t3h000004pOt1AAE
Package Alias: RFLIB@6.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOt1AAE

- [PR #80](https://github.com/j-fischer/rflib/pull/80) Permission Explorer: Added new mode to display object and field permissions for a specific user.
- Permission Explorer: Added user search to User Profile lookup.
- Permission Explorer: Changed API version for the REST API to v59.0 which fixes some gaps in the permission retrieval.
- Permission Explorer: Added button to select page size.
- Replaced all deprecated `if:true` and `if:false` directives with `lwc:if`.

### RFLIB 6.1.2

Package ID: 04t3h000004pOrKAAU
Package Alias: RFLIB@6.1.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOrKAAU

- Application Events: Fixed permissions in Create Application Event Permission Set.

### RFLIB 6.1.1

Package ID: 04t3h000004pOhAAAU
Package Alias: RFLIB@6.1.1-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOhAAAU

- Log Monitor: Fixed regression introduced in 6.1.0 that broke the Log Archive view.

### RFLIB 6.1.0

Package ID: DEPRECATED
Package Alias: RFLIB@6.1.0-2

- Log Archive: Added new Global Setting called Archive Log Query Limit to limit the number of results returned for a Big Object query
  This can help with the occurrence of Heap Limit exceptions that could be caussed by querying the archive.
- Management Dashboard: Updated rflibUserPermissionAssignmentList to include pagination to help with environments that have large user lists which could cause severe performance issues
- Management Dashboard: Added ORDER BY clause to queries of User Permission Assignments component

### RFLIB 6.0.0

Package ID: 04t3h000004pOeVAAU
Package Alias: RFLIB@6.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOeVAAU

- [PR #78](https://github.com/j-fischer/rflib/pull/78) Adding batch capabilities for the creation of application events
- Upgraded API version (`<apiVersion>`) to v59.0

### RFLIB 5.0.1

Package ID: 04t3h000004pOeQAAU
Package Alias: RFLIB@5.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOeQAAU

- [PR #79](https://github.com/j-fischer/rflib/pull/79) Replaced internal logger instances within RFLIB and RFLIB-FS from batch to regular.

### RFLIB-FS 3.0.1

Package ID: 04t3h000004pOeLAAU
Package Alias: RFLIB-FS@3.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOeLAAU

- Replaced internal logger instances within RFLIB and RFLIB-FS from batch to regular.

### RFLIB-FS 3.0.0

Package ID: 04t3h000004RffLAAS
Package Alias: RFLIB-FS@3.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RffLAAS

- REMOVED `rflib_FeatureSwitchPlugin` and test class. If you are using the plugin in your flows, please install RFLIB-FS v2.1 first and replace all occurrences with the new Invocable Action.

### RFLIB-FS 2.1.0

Package ID: 04t3h000004RffGAAS
Package Alias: RFLIB-FS@2.1.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RffGAAS

- Added new Flow Action to get RFLIB Feature Switch value in replacement for the legacy Plugin
- DEPRECATED `rflib_FeatureSwitchPlugin`, which will be removed in the RFLIB-FS 3.0.0 release.

### RFLIB 5.0.0

Package ID: 04t3h000004RfWlAAK
Package Alias: RFLIB@5.0.0-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RfWlAAK

- [PR #73](https://github.com/j-fischer/rflib/pull/73) Added new Application Event Framework to capture application events from various resources. For more information, please check out the [wiki](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Application-Events)
- [PR #76](https://github.com/j-fischer/rflib/pull/76) Salesforce Functions support for Application Events. For more information, please check out the [wiki](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Salesforce-Functions)
- Replaced interface `rflib_DefaultLogger.EventPublisher` with new interface `rflib_EventPublisher` and added a return value to the `publish()` method
- Added more Apex Doc comments

### RFLIB-TF 2.1.0

Package ID: 04t3h000004sqJMAAY
Package Alias: RFLIB-TF@2.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sqJMAAY

- [PR #69](https://github.com/j-fischer/rflib/pull/69) Added new framework for Retryable Actions, which allows for the use of platform events to run asynchronous tasks that will automatically be retried if they fail
- Changed package dependency on RFLIB to version 4.1.0

### RFLIB 4.1.0

Package ID: 04t3h000004sqJHAAY
Package Alias: RFLIB@4.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sqJHAAY

- [PR #69](https://github.com/j-fischer/rflib/pull/69) Updated `rflib_DefaultBigObjectDatabaseExecutor` to always use a Queueable for inserting a record into the Log Archive (see https://developer.salesforce.com/docs/atlas.en-us.bigobjects.meta/bigobjects/big_object_considerations.htm)
- [Issue #67](https://github.com/j-fischer/rflib/issues/67) Added handling of the edge case when the Request ID is null, which causes a NullPointerException in the default logger. If the request ID is null, a "NULL" string will be used as the request ID instead

### RFLIB 4.0.1

Package ID: 04t3h000004sqEgAAI
Package Alias: RFLIB@4.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sqEgAAI

- Improved CSS for the Management Dashboard's UserPermissionAssignmentList component
- Added icon for Logger Flow Action
- Introdcued query paramenter "c\_\_debug" that allows to trigger debugging mode for the EMP API
- Changed labels for all permission sets to have the "RFLIB - " prefix to make them eassier to find

### RFLIB-TF 2.0.0

Package ID: 04t3h000004sq62AAA
Package Alias: RFLIB-TF@2.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sq62AAA

- [PR #59](https://github.com/j-fischer/rflib/pull/59) Changed `apiVersion` of all components to version 55.0 (Summer 22)
- Changed package dependency on RFLIB to version 4.0.0 and RFLIB-FS to 2.0.0

### RFLIB-FS 2.0.0

Package ID: 04t3h000004sq5xAAA
Package Alias: RFLIB-FS@2.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sq5xAAA

- [PR #59](https://github.com/j-fischer/rflib/pull/59) Changed `apiVersion` of all components to version 55.0 (Summer 22)
- Changed package dependency on RFLIB to version 4.0.0

### RFLIB 4.0.0

Package ID: 04t3h000004RewHAAS
Package Alias: RFLIB@4.0.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RewHAAS

- [Issue #56](https://github.com/j-fischer/rflib/issues/56) Added new property to the log event to capture platform information such as Governor Limits (Apex), Browser Details (LWC), or Node process details (SF Functions)
- [PR #58](https://github.com/j-fischer/rflib/pull/58) Added Management Console to display org limits and users who are not assigned the Enable Client Logging permission set as well as users who are assigned to have Ops Center Access
- [PR #59](https://github.com/j-fischer/rflib/pull/59) Changed `apiVersion` of all components to version 55.0 (Summer 22)
- Added caching to Permission Explorer to avoid the loading of permissions after the first retrieval while switching between different permission types
- [Issue #60](https://github.com/j-fischer/rflib/isssues/60) Fixed bug throwing a JS exception in Log Monitor when filtering archived log messages through the Created By input.
- [Issue #54](https://github.com/j-fischer/rflib/isssues/54) Added option to cap the creation of log events based on Governor Limits

### RFLIB 3.2.0

Package ID: 04t3h000004mAiBAAU
Package Alias: RFLIB@3.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004mAiBAAU

- [Issue #54](https://github.com/j-fischer/rflib/issues/54) Added Global Config record to limit the amount of Platform Events that RFLIB will publish during a transaction
- Improved unit tests for code coverage and reliability

### RFLIB 3.1.2

Package ID: 04t3h000004mAhcAAE
Package Alias: RFLIB@3.1.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004mAhcAAE

- [Issue #52](https://github.com/j-fischer/rflib/issues/52) Improved unit tests for code coverage and reliability

### RFLIB-TF 1.4.0

Package ID: 04t3h000004jtc2AAA
Package Alias: RFLIB-FS@1.2.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jtc2AAA

- [Issue #47](https://github.com/j-fischer/rflib/issues/47) Changed log message for caught trigger handler exception to log at ERROR level instead of warning. The message does also indicate that the error was caught

### RFLIB-FS 1.2.1

Package ID: 04t3h000004jtbxAAA
Package Alias: RFLIB-FS@1.2.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jtbxAAA

- [Issue #49](https://github.com/j-fischer/rflib/issues/49) Bug fix for unit test failure as suggested by @mikbranchaud to handle triggers on the User object

### RFLIB 3.1.1

Package ID: 04t3h0000045uAmAAI
Package Alias: RFLIB@3.1.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h0000045uAmAAI

- [Issue #46](https://github.com/j-fischer/rflib/issues/46) Fixed broken Download button in Log Monitor Dashboard

### RFLIB 3.1.0

Package ID: 04t3h0000045uADAAY
Package Alias: RFLIB@3.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h0000045uADAAY

- [PR #45](https://github.com/j-fischer/rflib/pull/45) Added support for logging from Salesforce functions supporting NodeJS with Javascript and Typescript
- [Issue #43](https://github.com/j-fischer/rflib/issues/43) Fixed issue Client Log Size setting not taking effect

### RFLIB 3.0.1

Package ID: 04t3h000004bh4IAAQ
Package Alias: RFLIB@3.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bh4IAAQ

- [Issue #41](https://github.com/j-fischer/rflib/issues/41) - Renamed the rflib_Log_Archive**b Big Object to rflib_Logs_Archive**c (better than rflib_Log_Archive2\_\_c) in order to change the index
- Fixed issue with "Disconnect" not being displayed in button label

IMPORTANT: The rflib_Log_Archive\_\_b will be flagged for deletion but not physically deleted. Please remove manually at your earliest convenience.

### RFLIB 3.0.0

Package ID: DEPRECATED
Package Alias: RFLIB@3.0.0-1
Install link: N/A

- Added support for logging to Log Archive (Big Object), which can be queried through Log Monitor
- Log Monitor: Fixed issue when the connection would not re-establish after switching to Permission Explorer
- Permission Explorer: Permission Type button now changes the label to the actively selected type

### RFLIB 2.8.0

Package ID: 04t3h000004RdhnAAC
Package Alias: RFLIB@2.8.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdhnAAC

- Permission Explorer: Added Export to CSV button to Permission Explorer

### RFLIB-TF 1.3.1

Package ID: 04t3h000004RdhiAAC
Package Alias: RFLIB-TF@1.3.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdhiAAC

- [Issue #35](https://github.com/j-fischer/rflib/issues/35) - Updated TriggerManager to track active handlers on a per Object and Trigger Operation basis, invoking onConsecutive run only if the particular handler did complete the handling of an event previously

### RFLIB 2.7.0

Package ID: 04t3h000004RdZsAAK
Package Alias: RFLIB@2.7.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdZsAAK

- Permission Explorer: Optimized FLS query to return Fields stripped of their object name when using the REST API
- Permission Explorer: Added new component to resolve profile name by User Id to simplify entering of filter criteria
- Log Monitor: Added profile to the display of the user details in the Log Event Viewer
- Log Monitor: Fixed issue in the Ops Center Access Permission Set, which prevented non-admin users from receiving Log Events

### RFLIB 2.6.0

Package ID: 04t3h000004RdLTAA0
Package Alias: RFLIB@2.6.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdLTAA0

- Added support for querying over 50,000 permissions in Permission Explorer using the REST API
- Moved MockQueryExecutor from RFLIB-FS to RFLIB package

### RFLIB-TF 1.3.0

Package ID: 04t3h000004RdLOAA0
Package Alias: RFLIB-TF@1.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdLOAA0

- [Issue #31](https://github.com/j-fischer/rflib/issues/31) - Improved error handling if there are invalid trigger handler names in the configuration
- [Issue #30](https://github.com/j-fischer/rflib/issues/30) - Improved `rflib_MockTriggerConfigQueryLocator` to allow for setting multiple object handlers in a trigger unit test class

### RFLIB 2.5.0

Package ID: 04t3h000004Rd7uAAC
Package Alias: RFLIB@2.5.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004Rd7uAAC

- Added initial version of Permission Explorer
- Fixed issue with navigation buttons in Log Monitor getting confused when searching for Log Events

### RFLIB-TF 1.2.0

Package ID: 04t3h000004Rd1IAAS
Package Alias: RFLIB-TF@1.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004Rd1IAAS

- Replaced queries for Custom Metadata Type `rflib_Trigger_Configuration__mdt` with the new Apex API methods

### RFLIB-FS 1.2.0

Package ID: 04t3h000004RczqAAC
Package Alias: RFLIB-FS@1.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RczqAAC

- Replaced queries for Custom Metadata Type `rflib_Feature_Switch__mdt` with the new Apex API methods
- Changed log levels of some framework log messages from DEBUG to TRACE

### RFLIB 2.4.0

Package ID: 04t3h000004RczlAAC
Package Alias: RFLIB@2.4.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RczlAAC

- Replaced queries for Custom Metadata Type `rflib_Global_Setting__mdt` with the new Apex API methods

### RFLIB 2.3.0

Package ID: 04t3h000004jqfnAAA
Package Alias: RFLIB@2.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jqfnAAA

- Implemented finalizer interface support for Queueables
- Provided the ability to mask text within the collected log messages when publishing a log event

### RFLIB-FS 1.1.0

Package ID: 04t3h000004jqXEAAY
Package Alias: RFLIB-FS@1.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jqXEAAY

- Added new feature switch scope type called "Public Group" which allows for overwrites using direct public group memberships

### RFLIB-TF 1.1.0

Package ID: 04t3h000004jq2OAAQ
Package Alias: RFLIB-TF@1.1.0-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jq2OAAQ

- All metadata was upgraded to API version 50.0
- Added Custom Permission to allow to bypass all triggers

### RFLIB-FS 1.0.2

Package ID: 04t3h000004jpyMAAQ
Package Alias: RFLIB-FS@1.0.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jpyMAAQ

- All metadata was upgraded to API version 50.0

### RFLIB 2.2.0

Package ID: 04t3h000004jpwzAAA
Package Alias: RFLIB@2.2.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jpwzAAA

- All metadata was upgraded to API version 50.0
- Added input field for User filter Log Monitor
- Introduced the Salesforce Request ID into the logging framework
- Added Salesforce Request ID to TraceID token to make it completely unique
- Added Log Timer actions support for Flow
- Updated unit tests for Winter 21 release where new dedicated limits for publishing platform events immediately are introduced. See https://releasenotes.docs.salesforce.com/en-us/winter21/release-notes/rn_platform_events_publish_immediate_limit.htm?edition=&impact=

### RFLIB-TF 1.0.1

Package ID: 04t3h000004jnfBAAQ
Package Alias: RFLIB-TF@1.0.1-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jnfBAAQ

- Fixed issue with rflib_MockTriggerConfigQueryLocator that would fail tests for regular custom or standard objects
- Updated project dependency for RFLIB to version 2.1

### RFLIB 2.1.0

Package ID: 04t3h000004jnf6AAA
Package Alias: RFLIB@2.1.0-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jnf6AAA

- Introduced Log Timer for LWC, Aura, and Apex to add a log statement including the duration of the timer
- Added new custom setting to set the log level for when to flush log statements after a Log Event is published, default level is NONE
- Fixed bug where the Log Reporting Level did not allow for NONE as a valid value

### RFLIB-FS 1.0.1

Package ID: 04t3h000004jmovAAA
Package Alias: RFLIB-FS@1.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jmovAAA

- Added rflib_Enable_Client_Feature_Switches permission set (moved from RFLIB package)

### RFLIB 2.0.1

Package ID: 04t3h000004jmoqAAA
Package Alias: RFLIB@2.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jmoqAAA

- Removed rflib_Enable_Client_Feature_Switches permission set from package (to be added to RFLIB-FS)

### RFLIB-TF 1.0.0

Package ID: 04t3h000004bcWpAAI
Package Alias: RFLIB-TF@1.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcWpAAI

- RFLLB-TF 1.0.0 contains the Trigger Framework, which depends on RFLIB 2.0.0 and RFLIB-FS 1.0.0
- All metadata was upgrade to API version 49.0

### RFLIB-FS 1.0.0

Package ID: 04t3h000004bcXJAAY
Package Alias: RFLIB-FS@1.0.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcXJAAY

- RFLIB-FS 1.0.0 contains the Feature Switch framework and depends on RFLIB 2.0.0
- All metadata was upgrade to API version 49.0

### RFLIB 2.0.0

Package ID: 04t3h000004bcWfAAI
Package Alias: RFLIB@2.0.0-4
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcWfAAI

- RFLIB 2.0.0 contains the core logging framework. The log event email handler got converted into a Invocable Action, which is used by a Platform Event triggered Flow to send out the email message based on the configuration in the Logger Settings
- RFLIB-FS 1.0.0 contains the Feature Switch framework and depends on RFLIB 2.0.0
- RFLLB-TF 1.0.0 contains the Trigger Framework, which depends on RFLIB 2.0.0 and RFLIB-FS 1.0.0
- All metadata was upgrade to API version 49.0

### RFLIB 1.0.1

Package ID: 04t3h000004bbNiAAI
Package Alias: RFLIB@1.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bbNiAAI

- Fixed issue in rflibLogger.setConfig where new server and console log levels failed to take effect
- Fixed issue in rflibFeatureSwitch where a failed request to the Apex action would return an undefined exception instead of the server error
- Added LWC unit tests
- Build script improvements

### RFLIB 1.0.0

Package ID: 04t3h000002rTGPAA2
Package Alias: RFLIB@1.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000002rTGPAA2

- **May 2020** - Bug fixes
- **Apr 2020** - Added TRACE log level, rebranding, multiple enhancements to the core framework including log batching
- **Mar 2020** - Enhanced email reporting and introduced log batching
- **Feb 2020** - Added application to review log events for the last 24 hours as well as in real-time on a dashboard
- **Jan 2020** - Added Feature Switches implementation including switch to suspend all triggers
- **Dec 2019** - Added `HttpRequest` wrapper and Trace ID implementation
- **Nov 2019** - Initial release with Trigger pattern, LWC/LC logger, and Apex logger
