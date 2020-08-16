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
-   All metadata was upgrade to API version 49.0.

### RFLIB-FS 1.0.0

Package ID: 04t3h000004bcXJAAY
Package Alias: RFLIB-FS@1.0.0-2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcXJAAY

-   RFLIB-FS 1.0.0 contains the Feature Switch framework and depends on RFLIB 2.0.0
-   All metadata was upgrade to API version 49.0.

### RFLIB 2.0.0

Package ID: 04t3h000004bcWfAAI
Package Alias: RFLIB@2.0.0-4
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bcWfAAI

-   RFLIB 2.0.0 contains the core logging framework. The log event email handler got converted into a Invocable Action, which is used by a Platform Event triggered Flow to send out the email message based on the configuration in the Logger Settings
-   RFLIB-FS 1.0.0 contains the Feature Switch framework and depends on RFLIB 2.0.0
-   RFLLB-TF 1.0.0 contains the Trigger Framework, which depends on RFLIB 2.0.0 and RFLIB-FS 1.0.0
-   All metadata was upgrade to API version 49.0.

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
