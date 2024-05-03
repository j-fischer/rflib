rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('TestContext');

rflib_HttpRequest req = new rflib_HttpRequest();

req.setEndpoint('https://api.example.com/data');
req.setMethod('GET');
req.setBody('{"key": "value"}');
req.setHeader('Content-Type', 'application/json');

HttpResponse response = req.send();

LOGGER.info('Response Status: ' + response.getStatus());
LOGGER.info('Response Body: ' + response.getBody());