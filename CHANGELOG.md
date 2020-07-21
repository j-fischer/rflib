### 1.0.1

Package ID: 04t3h000004bbNiAAI
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004bbNiAAI

-   Fixed issue in rflibLogger.setConfig where new server and console log levels failed to take effect
-   Fixed issue in rflibFeatureSwitch where a failed request to the Apex action would return an undefined exception instead of the server error
-   Added LWC unit tests
-   Build script improvements

### 1.0.0

Package ID: 04t3h000002rTGPAA2
Install link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000002rTGPAA2

-   **May 2020** - Bug fixes
-   **Apr 2020** - Added TRACE log level, rebranding, multiple enhancements to the core framework including log batching
-   **Mar 2020** - Enhanced email reporting and introduced log batching
-   **Feb 2020** - Added application to review log events for the last 24 hours as well as in real-time on a dashboard
-   **Jan 2020** - Added Feature Switches implementation including switch to suspend all triggers
-   **Dec 2019** - Added `HttpRequest` wrapper and Trace ID implementation
-   **Nov 2019** - Initial release with Trigger pattern, LWC/LC logger, and Apex logger
