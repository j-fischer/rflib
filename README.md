# Reliability Force

[![Build Status](https://travis-ci.org/j-fischer/rflib.svg?branch=master)](https://travis-ci.org/j-fischer/rflib)

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

#### Feature Switches (package RFLIB-FS):

-   Fully configured using Custom Metadata
-   Supports hierarchical structure (similar to Custom Settings) to override settings at the profile or user level
-   Fully supported in Flow Builder through Get Records or Apex Action

#### Trigger Framework (package RFLIB-TF):

-   Fully decoupled framework, trigger handlers work in isolation
-   Recursion tracking to allow for easy prevention of multiple executions
-   Fully configurable trigger management (activation, order, error handling, etc) using Custom Metadata

## Deploy

**The best way to add RFLIB to your environment is by installing the unlocked package.**

Alternatively, you can either clone the repository and use 'sfdx force:source:deploy' to deploy this library to your Sandbox or use the **Deploy to Salesforce**
button below to deploy it directly into your org.

Please check the [CHANGELOG file](https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md) for versions, install links and package aliases.

To install package via browser:

https://login.salesforce.com/packaging/installPackage.apexp?p0=<PACKAGE_VERSION_ID>

To install latest package via SFDX CLI Plugin:

```
sfdx sforce:package:install -p RFLIB@2.1.0-3 -w 10 -s AllUsers -u <your org alias>
sfdx sforce:package:install -p RFLIB-FS@1.0.1-1 -w 10 -s AllUsers -u <your org alias>
sfdx sforce:package:install -p RFLIB-TF@1.0.1-3 -w 10 -s AllUsers -u <your org alias>
```

To deploy code:

<a href="https://githubsfdeploy.herokuapp.com/?owner=j-fischer&repo=rflib&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

## Documentation

Documentation such as How To's and more can be found in the [Wiki of this repository](https://github.com/j-fischer/rflib/wiki/Ops-Center-Logging-Dashboard).

## Log Event Dashboard

Review any log events sent within the last 72 hours or receive new log events in real-time. The dashboard shows all the events and lets you
filter them by searching text within the messages. This will make it easy to detect error codes or other log messages of value.

To enabled the Ops Center application, simply assign the `Ops Center Access` Permission Set to the users of your choice.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Log_Monitor_Dashboard.gif 'Log Monitor Dashboard')

## Updates

See [CHANGELOG file](https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md) for versions, install links and package IDs.

## Credits

-   Table Pagination was inspired by: https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
-   Log Monitor Component was inspired by: https://github.com/rsoesemann/apex-unified-logging
-   The unlocked packaged was created with the help of Andrew Fawcett: https://andyinthecloud.com/2018/06/16/salesforce-dx-packages-and-open-source/
-   Logo was created with: https://www.freelogodesign.org/
-   Thanks to Fabien Taillon for his SFDX CLI Plugin: https://github.com/texei/texei-sfdx-plugin
-   Thanks to René Winkelmeyer for his SFDX CLI Plugin: https://github.com/muenzpraeger/sfdx-plugin
-   Thanks to Shane McLaughlin for his SFDX CLI Plugin: https://github.com/mshanemc/shane-sfdx-plugins
