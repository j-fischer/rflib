### RFLIB 6.4.0

Package ID: 04t3h000004pOv7AAE
Package Alias: RFLIB@6.4.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOv7AAE

-   Permission Explorer: Added two new modes to query Permission Set Groups specifically and added filter to exclude Permission Set Groups when looking up Permission Sets only.
-   Permission Explorer: Improved handling of error messages when retrieving permissions from the controller.

### RFLIB-TF 3.0.1

Package ID: 04t3h000004pOuxAAE
Package Alias: RFLIB-TF@3.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOuxAAE

-   Trigger Framework: Refactored handling of Feature Switches to invert behaviour so that they don't need to be configured. CHANGED NAME OF FEATURE SWITCHES FOR TRIGGERS AND RETRYABLE ACTION. Renamed the Feature Switches used from All_Triggers to rflib_Disable_All_Triggers and from All_Retryable_Actions to flib_Disable_All_Retryable_Actions. The old values will not be considered anymore.
    IMPORTANT: THIS CHANGE BREAKS BACKWARDS COMPATIBILITY IF THOSE TRIGGER SWITCHES ARE USED.

### RFLIB 6.3.1

Package ID: 04t3h000004pOusAAE
Package Alias: RFLIB@6.3.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOusAAE

-   Removed Global Setting CMT record Archive Log Query Limit, which was missed in the 6.3.0 release.

### RFLIB 6.3.0

Package ID: 04t3h000004pOuTAAU
Package Alias: RFLIB@6.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOuTAAU

-   [PR #81](https://github.com/j-fischer/rflib/pull/81) Added new Global Setting config value to choose whether to use the Org Wide Email Address for sending out notifications or not. This allows orgs to take advantage of the new configuration setting to select the workflow user for record triggered flows. See https://help.salesforce.com/s/articleView?id=release-notes.rn_automate_flow_builder_run_event_triggered_flows_as_workflow_user.htm&release=248&type=5
-   Log Monitor: Fixed bug where the query limit message would not be displayed when viewing the Log Archive.
-   Removed all Global Setting CMT records and aligned their validation rules according to the documentation. (Update: Missed Archive Log Query Limit)

### RFLIB 6.2.0

Package ID: 04t3h000004pOt1AAE
Package Alias: RFLIB@6.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOt1AAE

-   [PR #80](https://github.com/j-fischer/rflib/pull/80) Permission Explorer: Added new mode to display object and field permissions for a specific user.
-   Permission Explorer: Added user search to User Profile lookup.
-   Permission Explorer: Changed API version for the REST API to v59.0 which fixes some gaps in the permission retrieval.
-   Permission Explorer: Added button to select page size.
-   Replaced all deprecated `if:true` and `if:false` directives with `lwc:if`.

### RFLIB 6.1.2

Package ID: 04t3h000004pOrKAAU
Package Alias: RFLIB@6.1.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOrKAAU

-   Application Events: Fixed permissions in Create Application Event Permission Set.

### RFLIB 6.1.1

Package ID: 04t3h000004pOhAAAU
Package Alias: RFLIB@6.1.1-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOhAAAU

-   Log Monitor: Fixed regression introduced in 6.1.0 that broke the Log Archive view.

### RFLIB 6.1.0

Package ID: DEPRECATED
Package Alias: RFLIB@6.1.0-2

-   Log Archive: Added new Global Setting called Archive Log Query Limit to limit the number of results returned for a Big Object query
    This can help with the occurrence of Heap Limit exceptions that could be caussed by querying the archive.
-   Management Dashboard: Updated rflibUserPermissionAssignmentList to include pagination to help with environments that have large user lists which could cause severe performance issues
-   Management Dashboard: Added ORDER BY clause to queries of User Permission Assignments component

### RFLIB 6.0.0

Package ID: 04t3h000004pOeVAAU
Package Alias: RFLIB@6.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOeVAAU

-   [PR #78](https://github.com/j-fischer/rflib/pull/78) Adding batch capabilities for the creation of application events
-   Upgraded API version (`<apiVersion>`) to v59.0

### RFLIB 5.0.1

Package ID: 04t3h000004pOeQAAU
Package Alias: RFLIB@5.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOeQAAU

-   [PR #79](https://github.com/j-fischer/rflib/pull/79) Replaced internal logger instances within RFLIB and RFLIB-FS from batch to regular.

### RFLIB-FS 3.0.1

Package ID: 04t3h000004pOeLAAU
Package Alias: RFLIB-FS@3.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004pOeLAAU

-   Replaced internal logger instances within RFLIB and RFLIB-FS from batch to regular.

### RFLIB-FS 3.0.0

Package ID: 04t3h000004RffLAAS
Package Alias: RFLIB-FS@3.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RffLAAS

-   REMOVED `rflib_FeatureSwitchPlugin` and test class. If you are using the plugin in your flows, please install RFLIB-FS v2.1 first and replace all occurrences with the new Invocable Action.

### RFLIB-FS 2.1.0

Package ID: 04t3h000004RffGAAS
Package Alias: RFLIB-FS@2.1.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RffGAAS

-   Added new Flow Action to get RFLIB Feature Switch value in replacement for the legacy Plugin
-   DEPRECATED `rflib_FeatureSwitchPlugin`, which will be removed in the RFLIB-FS 3.0.0 release.

### RFLIB 5.0.0

Package ID: 04t3h000004RfWlAAK
Package Alias: RFLIB@5.0.0-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RfWlAAK

-   [PR #73](https://github.com/j-fischer/rflib/pull/73) Added new Application Event Framework to capture application events from various resources. For more information, please check out the [wiki](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Application-Events)
-   [PR #76](https://github.com/j-fischer/rflib/pull/76) Salesforce Functions support for Application Events. For more information, please check out the [wiki](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Salesforce-Functions)
-   Replaced interface `rflib_DefaultLogger.EventPublisher` with new interface `rflib_EventPublisher` and added a return value to the `publish()` method
-   Added more Apex Doc comments

### RFLIB-TF 2.1.0

Package ID: 04t3h000004sqJMAAY
Package Alias: RFLIB-TF@2.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sqJMAAY

-   [PR #69](https://github.com/j-fischer/rflib/pull/69) Added new framework for Retryable Actions, which allows for the use of platform events to run asynchronous tasks that will automatically be retried if they fail
-   Changed package dependency on RFLIB to version 4.1.0

### RFLIB 4.1.0

Package ID: 04t3h000004sqJHAAY
Package Alias: RFLIB@4.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sqJHAAY

-   [PR #69](https://github.com/j-fischer/rflib/pull/69) Updated `rflib_DefaultBigObjectDatabaseExecutor` to always use a Queueable for inserting a record into the Log Archive (see https://developer.salesforce.com/docs/atlas.en-us.bigobjects.meta/bigobjects/big_object_considerations.htm)
-   [Issue #67](https://github.com/j-fischer/rflib/issues/67) Added handling of the edge case when the Request ID is null, which causes a NullPointerException in the default logger. If the request ID is null, a "NULL" string will be used as the request ID instead

### RFLIB 4.0.1

Package ID: 04t3h000004sqEgAAI
Package Alias: RFLIB@4.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sqEgAAI

-   Improved CSS for the Management Dashboard's UserPermissionAssignmentList component
-   Added icon for Logger Flow Action
-   Introdcued query paramenter "c\_\_debug" that allows to trigger debugging mode for the EMP API
-   Changed labels for all permission sets to have the "RFLIB - " prefix to make them eassier to find

### RFLIB-TF 2.0.0

Package ID: 04t3h000004sq62AAA
Package Alias: RFLIB-TF@2.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sq62AAA

-   [PR #59](https://github.com/j-fischer/rflib/pull/59) Changed `apiVersion` of all components to version 55.0 (Summer 22)
-   Changed package dependency on RFLIB to version 4.0.0 and RFLIB-FS to 2.0.0

### RFLIB-FS 2.0.0

Package ID: 04t3h000004sq5xAAA
Package Alias: RFLIB-FS@2.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004sq5xAAA

-   [PR #59](https://github.com/j-fischer/rflib/pull/59) Changed `apiVersion` of all components to version 55.0 (Summer 22)
-   Changed package dependency on RFLIB to version 4.0.0

### RFLIB 4.0.0

Package ID: 04t3h000004RewHAAS
Package Alias: RFLIB@4.0.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RewHAAS

-   [Issue #56](https://github.com/j-fischer/rflib/issues/56) Added new property to the log event to capture platform information such as Governor Limits (Apex), Browser Details (LWC), or Node process details (SF Functions)
-   [PR #58](https://github.com/j-fischer/rflib/pull/58) Added Management Console to display org limits and users who are not assigned the Enable Client Logging permission set as well as users who are assigned to have Ops Center Access
-   [PR #59](https://github.com/j-fischer/rflib/pull/59) Changed `apiVersion` of all components to version 55.0 (Summer 22)
-   Added caching to Permission Explorer to avoid the loading of permissions after the first retrieval while switching between different permission types
-   [Issue #60](https://github.com/j-fischer/rflib/isssues/60) Fixed bug throwing a JS exception in Log Monitor when filtering archived log messages through the Created By input.
-   [Issue #54](https://github.com/j-fischer/rflib/isssues/54) Added option to cap the creation of log events based on Governor Limits

### RFLIB 3.2.0

Package ID: 04t3h000004mAiBAAU
Package Alias: RFLIB@3.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004mAiBAAU

-   [Issue #54](https://github.com/j-fischer/rflib/issues/54) Added Global Config record to limit the amount of Platform Events that RFLIB will publish during a transaction
-   Improved unit tests for code coverage and reliability

### RFLIB 3.1.2

Package ID: 04t3h000004mAhcAAE
Package Alias: RFLIB@3.1.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004mAhcAAE

-   [Issue #52](https://github.com/j-fischer/rflib/issues/52) Improved unit tests for code coverage and reliability

### RFLIB-TF 1.4.0

Package ID: 04t3h000004jtc2AAA
Package Alias: RFLIB-FS@1.2.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jtc2AAA

-   [Issue #47](https://github.com/j-fischer/rflib/issues/47) Changed log message for caught trigger handler exception to log at ERROR level instead of warning. The message does also indicate that the error was caught

### RFLIB-FS 1.2.1

Package ID: 04t3h000004jtbxAAA
Package Alias: RFLIB-FS@1.2.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jtbxAAA

-   [Issue #49](https://github.com/j-fischer/rflib/issues/49) Bug fix for unit test failure as suggested by @mikbranchaud to handle triggers on the User object

### RFLIB 3.1.1

Package ID: 04t3h0000045uAmAAI
Package Alias: RFLIB@3.1.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h0000045uAmAAI

-   [Issue #46](https://github.com/j-fischer/rflib/issues/46) Fixed broken Download button in Log Monitor Dashboard

### RFLIB 3.1.0

Package ID: 04t3h0000045uADAAY
Package Alias: RFLIB@3.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h0000045uADAAY

-   [PR #45](https://github.com/j-fischer/rflib/pull/45) Added support for logging from Salesforce functions supporting NodeJS with Javascript and Typescript
-   [Issue #43](https://github.com/j-fischer/rflib/issues/43) Fixed issue Client Log Size setting not taking effect

### RFLIB 3.0.1

Package ID: 04t3h000004bh4IAAQ
Package Alias: RFLIB@3.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bh4IAAQ

-   [Issue #41](https://github.com/j-fischer/rflib/issues/41) - Renamed the rflib_Log_Archive**b Big Object to rflib_Logs_Archive**c (better than rflib_Log_Archive2\_\_c) in order to change the index
-   Fixed issue with "Disconnect" not being displayed in button label

IMPORTANT: The rflib_Log_Archive\_\_b will be flagged for deletion but not physically deleted. Please remove manually at your earliest convenience.

### RFLIB 3.0.0

Package ID: DEPRECATED
Package Alias: RFLIB@3.0.0-1
Install link: N/A

-   Added support for logging to Log Archive (Big Object), which can be queried through Log Monitor
-   Log Monitor: Fixed issue when the connection would not re-establish after switching to Permission Explorer
-   Permission Explorer: Permission Type button now changes the label to the actively selected type

### RFLIB 2.8.0

Package ID: 04t3h000004RdhnAAC
Package Alias: RFLIB@2.8.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdhnAAC

-   Permission Explorer: Added Export to CSV button to Permission Explorer

### RFLIB-TF 1.3.1

Package ID: 04t3h000004RdhiAAC
Package Alias: RFLIB-TF@1.3.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdhiAAC

-   [Issue #35](https://github.com/j-fischer/rflib/issues/35) - Updated TriggerManager to track active handlers on a per Object and Trigger Operation basis, invoking onConsecutive run only if the particular handler did complete the handling of an event previously

### RFLIB 2.7.0

Package ID: 04t3h000004RdZsAAK
Package Alias: RFLIB@2.7.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdZsAAK

-   Permission Explorer: Optimized FLS query to return Fields stripped of their object name when using the REST API
-   Permission Explorer: Added new component to resolve profile name by User Id to simplify entering of filter criteria
-   Log Monitor: Added profile to the display of the user details in the Log Event Viewer
-   Log Monitor: Fixed issue in the Ops Center Access Permission Set, which prevented non-admin users from receiving Log Events

### RFLIB 2.6.0

Package ID: 04t3h000004RdLTAA0
Package Alias: RFLIB@2.6.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdLTAA0

-   Added support for querying over 50,000 permissions in Permission Explorer using the REST API
-   Moved MockQueryExecutor from RFLIB-FS to RFLIB package

### RFLIB-TF 1.3.0

Package ID: 04t3h000004RdLOAA0
Package Alias: RFLIB-TF@1.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RdLOAA0

-   [Issue #31](https://github.com/j-fischer/rflib/issues/31) - Improved error handling if there are invalid trigger handler names in the configuration
-   [Issue #30](https://github.com/j-fischer/rflib/issues/30) - Improved `rflib_MockTriggerConfigQueryLocator` to allow for setting multiple object handlers in a trigger unit test class

### RFLIB 2.5.0

Package ID: 04t3h000004Rd7uAAC
Package Alias: RFLIB@2.5.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004Rd7uAAC

-   Added initial version of Permission Explorer
-   Fixed issue with navigation buttons in Log Monitor getting confused when searching for Log Events

### RFLIB-TF 1.2.0

Package ID: 04t3h000004Rd1IAAS
Package Alias: RFLIB-TF@1.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004Rd1IAAS

-   Replaced queries for Custom Metadata Type `rflib_Trigger_Configuration__mdt` with the new Apex API methods

### RFLIB-FS 1.2.0

Package ID: 04t3h000004RczqAAC
Package Alias: RFLIB-FS@1.2.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RczqAAC

-   Replaced queries for Custom Metadata Type `rflib_Feature_Switch__mdt` with the new Apex API methods
-   Changed log levels of some framework log messages from DEBUG to TRACE

### RFLIB 2.4.0

Package ID: 04t3h000004RczlAAC
Package Alias: RFLIB@2.4.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004RczlAAC

-   Replaced queries for Custom Metadata Type `rflib_Global_Setting__mdt` with the new Apex API methods

### RFLIB 2.3.0

Package ID: 04t3h000004jqfnAAA
Package Alias: RFLIB@2.3.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jqfnAAA

-   Implemented finalizer interface support for Queueables
-   Provided the ability to mask text within the collected log messages when publishing a log event

### RFLIB-FS 1.1.0

Package ID: 04t3h000004jqXEAAY
Package Alias: RFLIB-FS@1.1.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jqXEAAY

-   Added new feature switch scope type called "Public Group" which allows for overwrites using direct public group memberships

### RFLIB-TF 1.1.0

Package ID: 04t3h000004jq2OAAQ
Package Alias: RFLIB-TF@1.1.0-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jq2OAAQ

-   All metadata was upgraded to API version 50.0
-   Added Custom Permission to allow to bypass all triggers

### RFLIB-FS 1.0.2

Package ID: 04t3h000004jpyMAAQ
Package Alias: RFLIB-FS@1.0.2-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jpyMAAQ

-   All metadata was upgraded to API version 50.0

### RFLIB 2.2.0

Package ID: 04t3h000004jpwzAAA
Package Alias: RFLIB@2.2.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jpwzAAA

-   All metadata was upgraded to API version 50.0
-   Added input field for User filter Log Monitor
-   Introduced the Salesforce Request ID into the logging framework
-   Added Salesforce Request ID to TraceID token to make it completely unique
-   Added Log Timer actions support for Flow
-   Updated unit tests for Winter 21 release where new dedicated limits for publishing platform events immediately are introduced. See https://releasenotes.docs.salesforce.com/en-us/winter21/release-notes/rn_platform_events_publish_immediate_limit.htm?edition=&impact=

### RFLIB-TF 1.0.1

Package ID: 04t3h000004jnfBAAQ
Package Alias: RFLIB-TF@1.0.1-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jnfBAAQ

-   Fixed issue with rflib_MockTriggerConfigQueryLocator that would fail tests for regular custom or standard objects
-   Updated project dependency for RFLIB to version 2.1

### RFLIB 2.1.0

Package ID: 04t3h000004jnf6AAA
Package Alias: RFLIB@2.1.0-3
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jnf6AAA

-   Introduced Log Timer for LWC, Aura, and Apex to add a log statement including the duration of the timer
-   Added new custom setting to set the log level for when to flush log statements after a Log Event is published, default level is NONE
-   Fixed bug where the Log Reporting Level did not allow for NONE as a valid value

### RFLIB-FS 1.0.1

Package ID: 04t3h000004jmovAAA
Package Alias: RFLIB-FS@1.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jmovAAA

-   Added rflib_Enable_Client_Feature_Switches permission set (moved from RFLIB package)

### RFLIB 2.0.1

Package ID: 04t3h000004jmoqAAA
Package Alias: RFLIB@2.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004jmoqAAA

-   Removed rflib_Enable_Client_Feature_Switches permission set from package (to be added to RFLIB-FS)

### RFLIB-TF 1.0.0

Package ID: 04t3h000004bcWpAAI
Package Alias: RFLIB-TF@1.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcWpAAI

-   RFLLB-TF 1.0.0 contains the Trigger Framework, which depends on RFLIB 2.0.0 and RFLIB-FS 1.0.0
-   All metadata was upgrade to API version 49.0

### RFLIB-FS 1.0.0

Package ID: 04t3h000004bcXJAAY
Package Alias: RFLIB-FS@1.0.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcXJAAY

-   RFLIB-FS 1.0.0 contains the Feature Switch framework and depends on RFLIB 2.0.0
-   All metadata was upgrade to API version 49.0

### RFLIB 2.0.0

Package ID: 04t3h000004bcWfAAI
Package Alias: RFLIB@2.0.0-4
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcWfAAI

-   RFLIB 2.0.0 contains the core logging framework. The log event email handler got converted into a Invocable Action, which is used by a Platform Event triggered Flow to send out the email message based on the configuration in the Logger Settings
-   RFLIB-FS 1.0.0 contains the Feature Switch framework and depends on RFLIB 2.0.0
-   RFLLB-TF 1.0.0 contains the Trigger Framework, which depends on RFLIB 2.0.0 and RFLIB-FS 1.0.0
-   All metadata was upgrade to API version 49.0

### RFLIB 1.0.1

Package ID: 04t3h000004bbNiAAI
Package Alias: RFLIB@1.0.1-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bbNiAAI

-   Fixed issue in rflibLogger.setConfig where new server and console log levels failed to take effect
-   Fixed issue in rflibFeatureSwitch where a failed request to the Apex action would return an undefined exception instead of the server error
-   Added LWC unit tests
-   Build script improvements

### RFLIB 1.0.0

Package ID: 04t3h000002rTGPAA2
Package Alias: RFLIB@1.0.0-1
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000002rTGPAA2

-   **May 2020** - Bug fixes
-   **Apr 2020** - Added TRACE log level, rebranding, multiple enhancements to the core framework including log batching
-   **Mar 2020** - Enhanced email reporting and introduced log batching
-   **Feb 2020** - Added application to review log events for the last 24 hours as well as in real-time on a dashboard
-   **Jan 2020** - Added Feature Switches implementation including switch to suspend all triggers
-   **Dec 2019** - Added `HttpRequest` wrapper and Trace ID implementation
-   **Nov 2019** - Initial release with Trigger pattern, LWC/LC logger, and Apex logger
