# Reliability Force

The goal of this library is to help developers to create clean, production ready code with a high level of operational supportability.

This library is inspired by Dan Appleman's (see [Advanced Apex Programming](https://www.amazon.com/gp/product/1936754126/ref=as_li_tl?ie=UTF8&tag=apexbook-20&camp=1789&creative=9325&linkCode=as2&creativeASIN=1936754126&linkId=2e3446c23a7a7cc6c947ec1bb2480434))
logging design patter to collect better diagnositc information when dealing with errors in your Apex classes. This library expands
his concepts to provide detailed log information from Lightning Components and Lightning Web Components, giving developers more visibility
into the execution path on the client side, especially when dealing with production issues. The library provides configuration that allows to
automatically report any unexpected errors through Salesforce's latest technologies such as Platform Events.

## Key Features

The following lists describe some of the key features of rflib.

Logging Framework:

-   Logger for LWC and LC, which publishes logs the same way as Apex
-   Configuration through Custom Settings allowing for different log configurations between users
-   Aggregation of log statements when reporting
-   Using Platform Events for reporting of log statements

Trigger Framework:

-   Fully decoupled framework, trigger handlers work in isolation
-   Recursion tracking to allow for easy prevention of multiple executions
-   Fully configurable trigger management (activation, order, etc) using Custom Metadata

## Configuration Settings

The following options can be configured using custom settings:

-   General Log Level: The log level for which log statements will be included in the logs
-   System Debug Log Level: The log level for which log statements will be written to the System.debug logs
-   Reporting Log Level: The log level that will trigger the reporting of the currently stored log statements using platform event
-   Org Wide Email Sender: The email address that is required to send out reports using the Email Log Event Handler handler

## Deploy

You can either clone the repository and use 'sfdx force:source:deploy' to deploy this library to your Sandbox or use the **Deployto Salesforce**
button below to deploy it directly into your org.

<a href="https://githubsfdeploy.herokuapp.com?owner=j-fischer&rflib">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

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
    this.logger.info('Event ocurred, {0} - {1}', 'foo', 'bar'); // Note the variable length of arguments
}
```

### Logging in Lightning Component

Insert the wrapper component into any Lightning Component, preferrably at the top of the markup.

`<c:rflibLoggerCmp aura:id="logger" name="MyCustomContext" appendComponentId="false" />`

Then retrieve the logger from your controller or helper code.

```
({
	doInit: function(component, event, helper) {
		var logger = component.find('logger');

        logger.debug('This is a test > {0}-{1}', ['foo', 'bar']); // Note that second argument has to be a list
	}
})
```

### Logging in Apex

Create a logger in your Apex class using the following command.

`rflib_Logger logger = rflib_DefaultLogger.createFromCustomSettings('MyContext');`

Then call the log functions.

`logger.debug('This is a test -> {1}: {2}', new List<Object> { 'foo', 'bar' });`

### Trigger Framework

The trigger framework of this library requires custom metadata to be create for any trigger that you create. To add a new trigger, create a new Apex class that implements the `rflib_ITriggerHandler` interface and its methods.

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

### Log Event Dashboard

Review any log events sent within the last 24 hours or receive new log events in real-time. The dashboard shows all the events and lets you
filter the events by searching text within the messages. This will make it easy to detect error codes or other log messages of value.

To enabled the Log Monitor application, simply assign the `Log Monitor Access` Permission Set to the users of your choice.

![alt text](https://github.com/j-fischer/rflib/blob/master/screenshots/Log_Monitor_Dashboard.gif 'Log Monitor Dashboard')

## Updates

-   **Nov 2019** - Initial release with Trigger pattern, LWC/LC logger, and Apex logger
-   **Dec 2019** - Added `HttpRequest` wrapper and Trace ID implementation
-   **Jan 2020** - Added Feature Switches implementation including switch to suspend all triggers
-   **Feb 2020** - Added application to review log events for the last 24 hours as well as in real-time on a dashboard

## Credits

-   Table Pagination was inspired by: https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
-   Log Monitor Component was inspired by: https://github.com/rsoesemann/apex-unified-logging
