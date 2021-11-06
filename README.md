# Reliability Force

![Build Status](https://img.shields.io/circleci/build/github/j-fischer/rflib/master) ![GitHub](https://img.shields.io/github/license/j-fischer/rflib) ![GitHub package.json version](https://img.shields.io/github/package-json/v/j-fischer/rflib) [![codecov](https://codecov.io/gh/j-fischer/rflib/branch/master/graph/badge.svg)](https://codecov.io/gh/j-fischer/rflib)

The goal of this library is to help developers to create clean, production-ready code with a high level of operational supportability.

This library is inspired by Dan Appleman's (see [Advanced Apex Programming](https://www.amazon.com/gp/product/1936754126/ref=as_li_tl?ie=UTF8&tag=apexbook-20&camp=1789&creative=9325&linkCode=as2&creativeASIN=1936754126&linkId=2e3446c23a7a7cc6c947ec1bb2480434))
logging design pattern to collect better diagnostic information when dealing with errors in your Apex classes. This library expands
his concepts to provide detailed log information from Lightning Components and Lightning Web Components, giving developers more visibility
into the execution path on the client side, especially when dealing with production issues. The library can be configured to
automatically report any unexpected errors through Salesforce's latest technologies such as Platform Events.

## Key Features

The following lists describe some of the key features of rflib.

#### Logging Framework (package RFLIB):

-   Logger for LWC and Aura, which publishes logs the same way as Apex
-   Configuration through Custom Settings allowing for different log configurations between users
-   Aggregation of log statements when reporting
-   Using Platform Events for reporting of log statements
-   Support Batched Logging for when DML statements are not supported
-   Log Archive using Big Objects
-   Dashboard for all Object and Field permissions for Profiles and Permission Sets
-   Supports logging in Flow and Process Builder

#### Feature Switches (package RFLIB-FS):

-   Fully configured using Custom Metadata
-   Supports hierarchical structure (similar to Custom Settings) to override settings at the profile or user level
-   Fully supported in Flow Builder through Get Records or Apex Action

#### Trigger Framework (package RFLIB-TF):

-   Fully decoupled framework, trigger handlers work in isolation
-   Recursion tracking to allow for easy prevention of multiple executions
-   Fully configurable trigger management (activation, order, error handling, etc) using Custom Metadata Types

## Deploy

**The best way to add RFLIB to your environment is by installing the unlocked package.**

Alternatively, you can either clone the repository and use 'sfdx force:source:deploy' to deploy this library to your Sandbox or use the **Deploy to Salesforce**
button below to deploy it directly into your org.

Please check the [CHANGELOG file](https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md) for versions, install links and package aliases.

To install package via browser:

https://login.salesforce.com/packaging/installPackage.apexp?p0=<PACKAGE_VERSION_ID>

To install package via SFDX CLI Plugin:

```
sfdx force:package:install -p <Package ID> -w 10 -s AdminsOnly -u <your org alias>
```

To deploy code:

<a href="https://githubsfdeploy.herokuapp.com/?owner=j-fischer&repo=rflib&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

## Documentation

Documentation such as "How To's" and more can be found in the [Wiki of this repository](https://github.com/j-fischer/rflib/wiki/Ops-Center-Logging-Dashboard).

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

## Updates

See [CHANGELOG file](https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md) for versions, install links and package IDs.

## Credits

-   Table Pagination was inspired by: https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
-   Log Monitor Component was inspired by: https://github.com/rsoesemann/apex-unified-logging
-   "Bypass All Trigger" Custom Permission was inspired by: https://github.com/appero-com/MyTriggers
-   The unlocked packaged was created with the help of Andrew Fawcett: https://andyinthecloud.com/2018/06/16/salesforce-dx-packages-and-open-source/
-   Logo was created with: https://www.freelogodesign.org/
-   Thanks to Fabien Taillon for his SFDX CLI Plugin: https://github.com/texei/texei-sfdx-plugin
-   Thanks to René Winkelmeyer for his SFDX CLI Plugin: https://github.com/muenzpraeger/sfdx-plugin
-   Thanks to Shane McLaughlin for his SFDX CLI Plugin: https://github.com/mshanemc/shane-sfdx-plugins
-   Thanks to Simon Akbar for his amazing blog post: https://www.machinereadablepeople.net/home/2020/4/4/exporting-salesforce-field-level-security-and-object-access-with-the-data-loader
-   Thanks to Salesforce Labs for the Streaming Monitor package: https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FYEEWUA5
-   Thanks to Numaan Mahammad for Big Object Utility: https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000EcvSsUAJ 
-   Thanks to Marco Almodova for granting me his ConfirmationDialog component including the right to share it under the BSD-3-Clause license: https://github.com/marcoalmodova/confirm-dialog
-   Thanks to Pearl Lee (@thetechbee) and Aleksandra Radovanovic (@\_AleksM) for being such amazing supporters of my work and this library
