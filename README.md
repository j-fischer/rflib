# Reliability Force

The goal of this library is to help developers to create clean, production ready code with a high level of operational supportability.

This library is inspired by Dan Appleman's (see [Advanced Apex Programming](https://www.amazon.com/gp/product/1936754126/ref=as_li_tl?ie=UTF8&tag=apexbook-20&camp=1789&creative=9325&linkCode=as2&creativeASIN=1936754126&linkId=2e3446c23a7a7cc6c947ec1bb2480434))
logging design patter to collect better diagnositc information when dealing with errors in your Apex classes. This library expands
his concepts to provide detailed log information from Lightning Components and Lightning Web Components, giving developers more visibility
into the execution path on the client side, especially when dealing with production issues. The library provides configuration that allows to
automatically report any unexpected errors through Salesforce's latest technologies such as Platform Events.

## Deploy

You can either clone the repository and use 'sfdx force:source:deploy' to deploy this library to your Sandbox or use the **Deployto Salesforce**
button below to deploy it directly into your org.

<a href="https://githubsfdeploy.herokuapp.com?owner=j-fischer&rflib">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

## How To's

### Use in Lightning Web Component

Import the log factory using the following import:

`import { createLogger } from 'c/rflibLogger';`

Then declare a property in your module for the actual logger.

```
export default class MyModule extends LightningElement {

    logger = createLogger('MyModule');

    ...
```

Last, use the logger to record log statements.

```
handleSomeEvent(event) {
    this.logger.info('Event ocurred');
}
```

### Use in Lightning Component

Insert the wrapper component into any Lightning Component, preferrably at the top of the markup.

`<c:rflibLoggerCmp aura:id="logger" name="MyCustomContext" appendComponentId="false" />`

Then retrieve the logger from your controller or helper code.

```
({
	doInit: function(component, event, helper) {
		var logger = component.find('logger');

    logger.debug('This is a test > {0}-{1}', ['foo', 'bar']);
	}
})
```

### Use in Apex

Create a logger in your Apex class using the following command.

`rflib_Logger logger = rflib_DefaultLogger.createFromCustomSettings('MyContext');`

Then call the log functions.

`logger.debug('This is a test -> {1}: {2}', new List<Object> { 'foo', 'bar' });`

## Updates

-   **Oct 2019** - Initial release with Trigger pattern, LWC/LC logger, and Apex logger
