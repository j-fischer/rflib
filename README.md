# Reliability Force

![Build Status](https://img.shields.io/circleci/build/github/j-fischer/rflib/master) ![GitHub](https://img.shields.io/github/license/j-fischer/rflib) ![NPM package version](https://shields.io/npm/v/rflib) [![codecov](https://codecov.io/gh/j-fischer/rflib/branch/master/graph/badge.svg)](https://codecov.io/gh/j-fischer/rflib)

The goal of this library is to help developers to create clean, production-ready code with a high level of operational supportability.

This library is inspired by Dan Appleman's (see [Advanced Apex Programming](https://www.amazon.com/gp/product/1936754126/ref=as_li_tl?ie=UTF8&tag=apexbook-20&camp=1789&creative=9325&linkCode=as2&creativeASIN=1936754126&linkId=2e3446c23a7a7cc6c947ec1bb2480434))
logging design pattern to collect better diagnostic information when dealing with errors in your Apex classes. This library expands
his concepts to provide detailed log information from Lightning Components and Lightning Web Components, giving developers more visibility
into the execution path on the client side, especially when dealing with production issues. The library can be configured to
automatically report any unexpected errors through Salesforce's latest technologies such as Platform Events.

## Key Features

The following lists describe some of the key features of rflib.

#### Logging Framework (package RFLIB):

- [Logger for LWC and Aura](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Logging), which publishes logs the same way as Apex
- [Configuration through Custom Settings](https://github.com/j-fischer/rflib/wiki/Logger-Settings) allowing for different log configurations between users
- Aggregation of log statements when reporting
- Using Platform Events for reporting of log statements
- [Masking](https://github.com/j-fischer/rflib/wiki/Masking-Log-Messages) of content in Log Messages
- Log Archive using Big Objects
- Automatically [time and log](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-the-Log-Timer) execution duration
- Dashboard for all Object, Field, and Apex/VF Page permissions for Profiles, Permission Sets, and Permission Set Groups
- Supports logging in Flow and Process Builder
- Supports OmniScript and Integration Procedures in [OmniStudio](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Logging-in-OmniStudio)
- Display of platform details (Governor Limits, browser & NodeJS process details) for every Log Event
- [HTTP Request mocking framework](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Salesforce-Functions) to speed up integration development

#### Feature Switches (package RFLIB-FS):

- [Fully configured](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Feature-Switches) using Custom Metadata
- Supports hierarchical structure (similar to Custom Settings) to override settings at the profile or user level
- Fully supported in Flow Builder through Get Records or Apex Action

#### Trigger Framework (package RFLIB-TF):

- Fully decoupled [framework](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-the-Trigger-Framework), trigger handlers work in isolation
- Recursion tracking to allow for easy prevention of multiple executions
- Fully configurable trigger management (activation, order, error handling, etc) using Custom Metadata Types
- [Framework for Retryable Actions](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Retryable-Actions) using Platform Events for asynchronous actions with automatic retries

## Deploy

**The best way to add RFLIB to your environment is by installing the unlocked package.**

Alternatively, you can either clone the repository and use 'sfdx force:source:deploy' to deploy this library to your Sandbox or use the **Deploy to Salesforce**
button below to deploy it directly into your org.

Please check the [CHANGELOG file](https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md) for versions, install links and package aliases.

To install package via browser:

https://login.salesforce.com/packaging/installPackage.apexp?p0=<PACKAGE_VERSION_ID>

To install package via SFDX CLI Plugin (v2):

```
sf package install --package <Package ID> --target-org <your org alias>
```

Here are the commands for the latest versions:

```
rem RFLIB 8.1.0
sf package install --package 04tKY000000xBvXYAU --target-org <your org alias>

rem RFLIB-FS 3.0.1
sf package install --package 04t3h000004pOeLAAU --target-org <your org alias>

rem RFLIB-TF 3.0.2
sf package install --package 04tKY000000xAF1YAM --target-org <your org alias>
```

To deploy code:

<a href="https://githubsfdeploy.herokuapp.com/?owner=j-fischer&repo=rflib&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

See the [NPM Package Registry record for more details](https://www.npmjs.com/package/rflib).

## Documentation

Documentation such as "How To's" and more can be found in the [Wiki of this repository](https://github.com/j-fischer/rflib/wiki).

## Log Event Dashboard

Review any log events sent within the last 72 hours or receive new log events in real-time. The dashboard shows all the events and lets you
filter them by searching text within the messages. This will make it easy to detect error codes or other log messages of value.

To enabled the Ops Center application, simply assign the `Ops Center Access` Permission Set to the users of your choice.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Log_Monitor_Dashboard.gif 'Log Monitor Dashboard')

## Permissions Explorer

Review object and field permissions for profiles and permission Sets easily within the same user interface. Many problems encountered in an org trace back
to access issues. Using the Setup interface to review access for users is pretty inefficient. This dashboard provides access to all profiles and permissions
and allows for quick filtering of the results.

To enabled the Ops Center application, simply assign the `Ops Center Access` Permission Set to the users of your choice.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Permission_Explorer.gif 'Permissions Explorer')

## Management Console

A critical aspect of operating a Salesforce Org is managing Governor Limits. There are transactional and org-wide limits, some of which RFLIB is consuming
in order to report and display Log Events. While there are several different tools available to monitor org-wide Governor Limits, RFLIB provides a simple
way to stay on top of those as well through the `Management Console` tab.

There, users with access to the Ops Center can view the current consumption of the org-wide Governor Limits relevant to RFLIB. In addition, RFLIB will
display what users have not been provided with Permission Set to enable client logging and what users are assigned access to the Ops Center.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Management_Console.png 'Management Console')

## Application Event Dashboard

Whether a product owner wants to understand feature adoption or user behaviour, [Application Events](https://github.com/j-fischer/rflib/wiki/Getting-Started-with-Application-Events) provide visibility into the an
application's usage patterns and can help teams to make better decisions and learn more about their apps.

For operational teams, Application Events can be used to track integration requests and their outcomes, which can lead to a call to action to review
RFLIB log messages for more details.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Application_Event_Dashboard.jpg 'Application Event Dashboard')

## Updates

See [CHANGELOG file](https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md) for versions, install links and package IDs.

## Credits

- Table Pagination was inspired by: https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
- Log Monitor Component was inspired by: https://github.com/rsoesemann/apex-unified-logging
- "Bypass All Trigger" Custom Permission was inspired by: https://github.com/appero-com/MyTriggers
- The unlocked packaged was created with the help of Andrew Fawcett: https://andyinthecloud.com/2018/06/16/salesforce-dx-packages-and-open-source/
- Logo was created with: https://www.freelogodesign.org/
- Thanks to Fabien Taillon for his SFDX CLI Plugin: https://github.com/texei/texei-sfdx-plugin
- Thanks to René Winkelmeyer for his SFDX CLI Plugin: https://github.com/muenzpraeger/sfdx-plugin
- Thanks to Shane McLaughlin for his SFDX CLI Plugin: https://github.com/mshanemc/shane-sfdx-plugins
- Thanks to Simon Akbar for his amazing blog post: https://www.machinereadablepeople.net/home/2020/4/4/exporting-salesforce-field-level-security-and-object-access-with-the-data-loader
- Thanks to Salesforce Labs for the Streaming Monitor package: https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FYEEWUA5
- Thanks to Numaan Mahammad for Big Object Utility: https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000EcvSsUAJ
- Thanks to Marco Almodova for granting me his ConfirmationDialog component including the right to share it under the BSD-3-Clause license: https://github.com/marcoalmodova/confirm-dialog
- Thanks to Pearl Lee (@thetechbee) and Aleksandra Radovanovic (@\_AleksM) for being such amazing supporters of my work and this library

## Attribution

- Application Event Logger Action icon (SVG) provided by [yogiaprelliyanto](https://www.svgrepo.com/author/yogiaprelliyanto/) under the [CC Attribution License](https://www.svgrepo.com/page/licensing#CC%20Attribution)
