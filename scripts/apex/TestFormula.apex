rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('TestContext');

String formulaString = 'MID(Stacktrace__c, FIND(".", Stacktrace__c) + 1, FIND(".", Stacktrace__c, FIND(".", Stacktrace__c) + 1) - FIND(".", Stacktrace__c) - 1)';

FormulaEval.FormulaInstance ff = Formula.builder()
    .withReturnType(FormulaEval.FormulaReturnType.STRING)
    .withType(rflib_Log_Event__e.getSObjectType())
    .withFormula(formulaString)
    .build();

rflib_Log_Event__e logEvent = new rflib_Log_Event__e(
    Request_ID__c = Request.getCurrent().getRequestId(),
    Log_Level__c = rflib_LogLevel.WARN.toString(),
    Context__c = 'RFLIB_INTERNAL',
    Platform_Info__c = 'N/A',
    Log_Messages__c = 'A message',
    Log_Source__c = rflib_LogSource.Apex.toString(),
    Stacktrace__c = 'Class.SampleDataController.importSampleData: line 62, column 1'
);

LOGGER.info('Formula: ' + ff.evaluate(logEvent));