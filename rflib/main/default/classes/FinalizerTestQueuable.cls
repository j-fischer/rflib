public class FinalizerTestQueuable implements Queueable {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('FinalizerTestQueuable');

    public void execute(QueueableContext ctx) {
        LOGGER.debug('Executing queuable');
        
        Finalizer logFinalizer = rflib_LoggerUtil.createLogFinalizer(LOGGER);
        System.attachFinalizer(logFinalizer);
        
        LOGGER.debug('Log finalizer attached');
    }
}
