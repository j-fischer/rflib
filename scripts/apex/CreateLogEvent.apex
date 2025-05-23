rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('TestContext');
LOGGER.trace('TRACE log statement');
LOGGER.debug('DEBUG log statement');
LOGGER.info('INFO log statement');
LOGGER.warn('WARN log statement');
LOGGER.error('ERROR log statement');
LOGGER.fatal('FATAL log statement');
LOGGER.info(JSON.serialize(new Map<String, String>{'key1' => 'value1', 'key2' => 'value2'}));