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

#### Logging Framework:

-   Logger for LWC and LC, which publishes logs the same way as Apex
-   Configuration through Custom Settings allowing for different log configurations between users
-   Aggregation of log statements when reporting
-   Using Platform Events for reporting of log statements
-   Support Batched Logging for when DML statements are not supported

#### Trigger Framework:

-   Fully decoupled framework, trigger handlers work in isolation
-   Recursion tracking to allow for easy prevention of multiple executions
-   Fully configurable trigger management (activation, order, error handling, etc) using Custom Metadata

#### Feature Switches:

-   Fully configured using Custom Metadata
-   Supports hierarchical structure (similar to Custom Settings) to override settings at the profile or user level
-   Fully supported in Flow Builder through Get Records or Apex Action

## Configuration Settings

The following options can be configured using custom settings:

-   General Log Level: The log level for which log statements will be included in the logs
-   System Debug Log Level: The log level for which log statements will be written to the System.debug logs
-   Reporting Log Level: The log level that will trigger the reporting of the currently stored log statements using platform event
-   Org Wide Email Sender: The email address that is required to send out reports using the Email Log Event Handler handler

## Deploy

**The best way to add RFLIB to your environment is by installing the unlocked package.**

Alternatively, you can either clone the repository and use 'sfdx force:source:deploy' to deploy this library to your Sandbox or use the **Deploy to Salesforce**
button below to deploy it directly into your org.

Please check the `sfdx-project.json` file for all package version IDs.

To install package via browser:

https://login.salesforce.com/packaging/installPackage.apexp?p0=<PACKAGE_VERSION_ID>

To install latest package via SFDX CLI Plugin:

```
sfdx sforce:package:install -p RFLIB@2.0.0-4 -w 10 -u <your org alias>
sfdx sforce:package:install -p RFLIB-FS@1.0.0-1 -w 10 -u <your org alias>
sfdx sforce:package:install -p RFLIB-TF@1.0.0-1 -w 10 -u <your org alias>
```

To deploy code:

<a href="https://githubsfdeploy.herokuapp.com/?owner=j-fischer&repo=rflib&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

[![Deploy](https://deploy-to-sfdx.com/dist/assets/images/DeployToSFDX.svg)](https://deploy-to-sfdx.com)

## How To's

### Logging in Lightning Web Component

Import the log factory using the following import:

`import { createLogger } from 'c/rflibLogger';`

Then declare a property in your module for the actual logger.

```
export default class MyModule extends LightningElement {

    logger = createLogger('MyModule');

    ...
}
```

Last, use the logger to record log statements.

```
handleSomeEvent(event) {
    // Note the variable length of arguments
    this.logger.info('Event ocurred, {0} - {1}', 'foo', 'bar');
}
```

### Logging in Lightning Component

Insert the wrapper component into any Lightning Component, preferably at the top of the markup.

`<c:rflibLoggerCmp aura:id="logger" name="MyCustomContext" appendComponentId="false" />`

Then retrieve the logger from your controller or helper code.

```
({
	doInit: function(component, event, helper) {
		var logger = component.find('logger');

        // Note that second argument has to be a list
        logger.debug('This is a test > {0}-{1}', ['foo', 'bar']);
	}
})
```

### Logging in Apex

Create a logger in your Apex class using one of the following commands:

1. `rflib_Logger logger = rflib_LoggerUtil.getFactory().createLogger('MyContext');`
2. `rflib_Logger logger = rflib_LoggerUtil.getFactory().createBatchedLogger('MyContext');`

Then call the log functions.

`logger.debug('This is a test -> {1}: {2}', new List<Object> { 'foo', 'bar' });`

### Logging in Apex using the Batch pattern

Create a logger in your Apex class using the following command.

`rflib_Logger logger = rflib_DefaultLogger.createBatchedLoggerFromCustomSettings('MyContext');`

When using the batched logging pattern, the code is responsible for the publishing of the log events. This means that it is required to call the `rflib_Logger.publishBatchedLogEvents()` method at the end of any transaction. It does not matter what logger it is called on as all loggers manage batched log events globally. Batched logging will reduce the number of DML statements, especially for low log level configurations.

Following is an example of an Aura controller using the batch pattern:

```
// This will log all Log Events as batched events, independent of the settings.
private static final rflib_Logger LOGGER = rflib_DefaultLogger.createBatchedLoggerFromCustomSettings('MyController');

@AuraEnabled
public static String doSomething(){
    try {
        // Application logic here
        return 'Result';
    } catch (Exception ex) {
        LOGGER.fatal('DoSomething threw an exception', ex);
    } finally {
        LOGGER.publishBatchedLogEvents();
    }
}
```

### Logger Settings

All log settings have help text that provides guidance about the valid values. Below is a list of all
existing configuration options with additional context information.

| **Setting**                       | **What is it for?**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | **Default value**          | **Recommended Sandbox Value**            | **Recommended Production Value** |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------- | ---------------------------------------- | -------------------------------- |
| Client Log Size                   | Defines how many messages are cached in the browser. 100 messages are more than sufficient. It could easily be less. Even with larger strings, i.e. full payloads from server requests, I have never found it to impact performance.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | 100                        | 100                                      | 100                              |
| Client Console Log Level          | Defines what log statements will be printed to the Browser's developer console. These messages can be seen by any user if they open those tools. This setting is configured for development and testing in Sandboxes, and it is recommended to change the value for Production.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | DEBUG                      | DEBUG                                    | NONE                             |
| Client Server Log Level           | Defines what log messages will trigger a server request to send out a Log Event platform event. Please note that this setting ignores the Log Event Reporting Level, which means that even if the client log level is of lower priority, it will still trigger the platform event. Reducing this level in production can sometimes be helpful when diagnosing a specific issue. It is not recommended to set this value below WARN, at least not on a global scope.                                                                                                                                                                                                                                                                                                                  | WARN                       | WARN                                     | WARN                             |
| Log Size                          | Defines how many messages are cached in the browser. 100 messages are more than sufficient. It could easily be less. Even with larger strings, i.e. full payloads from HTTP requests and response, I have \ never found it to impact performance.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | 100                        | 100                                      | 100                              |
| General Log Level                 | Defines the log level for which log statements are recorded in the cache. Any message below this level will be ignored. Typically, this setting should be set as low as possible, trying to find the balance between valuable content for the majority of the debug sessions, and optionally additional value for specific problems.                                                                                                                                                                                                                                                                                                                                                                                                                                                 | INFO                       | INFO                                     | INFO                             |
| System Debug Log Level            | Defines what log statements will be logged to the Salesforce System logs. These messages can be seen by Administrators after enabling a Debug Log in Setup. Debug logs can grow in size significantly and contain a lot of platform information. It is therefore recommended to only use DEBUG in production when debugging specific issues that require that level of detail. Most messages should be written as INFO level, which should be sufficient in most situations.                                                                                                                                                                                                                                                                                                         | DEBUG                      | DEBUG                                    | INFO                             |
| Log Event Reporting Level         | Defines what log messages will trigger a Log Event platform event. The Platform Event can be viewed in the Log Monitor Dashboard, where users can also download the log file. Reducing this level in production can sometimes be helpful when diagnosing a specific issue. It is not recommended to set this value below WARN on a global scope. The lowest level this setting can be set to is INFO.                                                                                                                                                                                                                                                                                                                                                                                | WARN                       | WARN                                     | WARN                             |
| Batched Log Event Reporting Level | Reporting a Log Event platform event will consume an DML request from your governor limits. Furthermore, there are situations where reporting a Log Event itself can cause a runtime exception because DML statements are not allowed. There are two ways to get around this issue. A `rflib_DefaultLogger` can be configured to batch all logs, and by setting the value of this field. This can also be critical when debugging an issue that may require lowering the log level to a level that may then cause before mentioned exceptions. Please note that whenever log batching is enabled, it is required to call the `rflib_Logger.publishBatchedLogEvents()` method for the events to actually get dispatched. If this commit is missing, the events will never be emitted. | NONE                       | NONE                                     | NONE                             |
| Email Log Level                   | Defines what Log Events should be sent out to the Apex Exception Email list. In most cases, it is desired to review more log messages in the Log Monitor Dashboard, but only to be notified for severe cases. When the log level of the message that triggered the Log Event matches this level, a notification with the details will be sent out. This way, admins do not have to monitor the Dashboard regularly in production.                                                                                                                                                                                                                                                                                                                                                    | NONE                       | Dev Sandboxes: NONE UAT/Pre-Prod: FATAL  | FATAL                            |
| Org Wide Email Sender Address     | Defines the email address to be used to send out the email notifications. The email must be configured and activated in the Organization Wide Email Addresses list.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |                            | UAT/Pre-Prod: Set to valid email address | Set to valid email address       |
| Logger Factory Class              | This field identifies the class to be used as a logger factory, which can be dynamically loaded using the `rflib_LoggerUtil.getFactory()` method. This class will then be instantiated and used to create the logger instance.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | rflib_DefaultLoggerFactory | rflib_DefaultLoggerFactory               | rflib_DefaultLoggerFactory       |

### Logging in Process Builder and Flow Builder

Logging is also supported in Process Builder and Flow using Apex Actions.

In Process Builder, define an Action with the Action Type `Apex`, give it a unique name and then select the Apex Class `Log Message`. Fill out the fields to log a message during the Process Builder execution. Please note that there are two optional parameters that can be configured when clicking at the `Add Row` button at the bottom of the form. The screenshot below illustrates the configuration.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Log_Message_Action_Process_Builder.png 'Process Builder Log Message Action')

In Flow Builder, add an `Action` element to your Flow. When the New Action modal appears, select `RFLIB` as the category on the left and search for the `Log Message` action in the right column. Once selected, fill out the standard action fields by giving it a unique name, and define your log parameters. Please note that there are two optional parameters that can be configured by enabling the toggle at the bottom of the form.The screenshot below illustrates the configuration.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Log_Message_Action_Flow.png 'Flow Builder Log Message Action')

### Logging Recommendations

Logging is a bit of an art. There is not right or wrong way, so anything described in this section is simply a recommendation based on previous experiences. I hope this will be helpful when writing your code. These are my best practices:

-   Generally use INFO statements
-   Try to create a log "stacktrace", which means that almost every function should have a log statement at the beginning with the arguments
-   Use TRACE statements within loops or for extremely large payloads
-   Every class or lightning component should have a logger instance
-   Use FATAL statements when catching unexpected exceptions in Aura Controller classes
-   Use ERROR statements in service classes, i.e. when catching errors after making a callout
-   Consider using the batch logger for classes dealing with callouts to avoid runtime exceptions created by the log framework
-   Use WARN level for situations that are recoverable, but should not really happen in the real world
-   Reduce log statements by using the formatting feature to easily print multiple variables in a single statement
-   Use `rflib_HttpRequest` instead of the Apex platform class, this can save hours of debugging integration issues
-   Build your code (controllers, trigger handlers, etc.) for batched logging (see Logging in Apex using the Batch pattern)

### Trigger Framework

The trigger framework of this library requires custom metadata to be create for any trigger that you create. To add a new trigger, create a new Apex class that implements the `rflib_TriggerHandler` interface and its methods.

Next, create the actual trigger, i.e. an Account trigger as displayed below. It is recommended to create the trigger for all events so that future trigger additions only require the new class and the custom metadata record.

```
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, before undelete) {
    rflib_TriggerManager.dispatch(Account.SObjectType);
}
```

Once the trigger is created, the framework will take care of the rest.

To create a test class for any new triggers, simply copy the `rflib_LogEventTriggerTest` class and rename the object to the object of your new trigger. Obviously, you need to create a record for the DML operation. Once this is done and the test passes, you won't have to touch the test case again. Any new handlers are tested in isolation and do not require the actual creation of records.

### Trace ID

Integration plays a very big part in today's enterprise IT environments. This means that Salesforce exchanges data with other
systems such as order management or financial systems. When the integration runs successfully, life is good, but if somehting goes wrong then it can be difficult to understand what the root cause is. It often requires the support team to investigate in multiple log files, where they have to find relevant log statements. And the same needs to be done for each system involved in the integration.

The intention of the Trace ID is to improve investigations by providing a common piece of data that can be included in all log files that belong to a single transaction across systems. The Trace ID should be generated in the system where the transaction originates and then be handed over to the other applications. Since most integrations today use the HTTP protocol, a non-intrusive way to transfer the ID is to add it as a custem header.

To hide this type of management from developers, rflib contains a new utility class called `rflib_HttpRequest` that wraps the actual `HttpRequest`. It automatically adds the Trace ID based on the header name configured in the `rflib_Global_Setting.mtd`. By default, the Trace ID in rflib is set to be the ID of the current user, but it can be easily replaced with other values. Below is a small example on how to use the class.

```
rflib_HttpRequest req = new rflib_HttpRequest();
req.setEndpoint('http://www.yahoo.com');
req.setMethod('GET');

// Set headers, body, etc.

// Use the send() of the rflib_HttpRequest
// instead of creating an instance of the Http class.

HttpResponse res = req.send();
System.debug(res.getBody());
```

### Feature Switches

Feature switches are an integral part of modern org development. For example, they allow features to be deployed but hidden from the users for an extended period of time. They also enable A/B testing, or provide the ability to turn functionality, i.e. a system integration, off during an outage. All of this can be done using Salesforce configuration interface instead of requiring a full deployment.
The Feature Switch implementation of rflib is based on Custom Metadata Types, but includes an implementation that enables a hierarchical configuration users know and love about Custom Settings.

To use Features Switches, simply add a new record to the Custom Metadata Type called "Feature Switch" and check the switch using the Apex utility class `rflib_FeatureSwitch`.

The default value for a feature switch without any matching configuration is `false`.

Below is an example on how the feature switch is evaluated in the Trigger Manager class.

```
private static void dispatch(rflib_TriggerManager.Args args) {
    List<TriggerHandlerInfo> handlers = getHandlers(args);

    if (rflib_FeatureSwitch.isTurnedOff('All_Triggers')) {
        LOGGER.warn('All Trigger Feature switch turned off, exiting trigger execution.');
        return;
    }

    // more code...
}
```

You can also use features switches on the client side. For LWC, use the following syntax:

```
import { isFeatureSwitchTurnedOn } from 'c/rflibFeatureSwitches';

handleSomeEvent(event) {
    isFeatureSwitchTurnedOn('mySwitchName')
        .then(isTurnedOn => {
            if (isTurnedOn) {
                // do something
            }
        });
}

```

In Aura components, add the feature switch component in the .cmp file.

`<c:rflibFeatureSwitches aura:id="featureSwitches" />`

In the controller or helper, you can then validate a feature switch with the following code snippet:

```
({
	doInit: function(component, event, helper) {
		var featureSwitches = component.find('featureSwitches');
		featureSwitches.isFeatureSwitchTurnedOn('All_Triggers')
			.then(function (isTunedOn) {
				logger.info('All_Triggers turned on? ' + isTunedOn);
			});
	}
})
```

In Flow Builder, `Global` feature switches can easily be accessed using the `Get Records` element. See the screenshot below for a sample configuration.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Feature_Switch_Flow_Get_Records.png 'Get Records Configuration')

If you would like to retrieve a full hierarchical feature switch value, that can be overwritten on a profile of user level, use the Apex Action displayed below.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Feature_Switch_Flow_Plugin.png 'Apex Action Configuration')

### Log Event Dashboard

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
