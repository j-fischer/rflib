// File: rflib_ApexJobScheduler.cls
public with sharing class rflib_ApexJobScheduler {
    
    // Instantiate the RFLIB Logger with a context-specific identifier
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_ApexJobScheduler');

    /**
     * Method to get job details by class name.
     *
     * @param className The name of the Apex class to monitor.
     * @return ScheduledJobDetails containing job status and schedule information.
     */
    @AuraEnabled(cacheable=true)
    public static ScheduledJobDetails getJobDetails(String jobName) {
        LOGGER.info('getJobDetails called with jobName: ' + jobName);
        ScheduledJobDetails details = new ScheduledJobDetails();
        try {
            List<CronTrigger> cronTriggers = [
                SELECT Id, CronExpression, TimesTriggered, NextFireTime, State 
                FROM CronTrigger 
                WHERE CronJobDetail.Name = :jobName 
                LIMIT 1
            ];
            LOGGER.debug('Fetched CronTriggers count: ' + String.valueOf(cronTriggers.size()));
            
            if (!cronTriggers.isEmpty()) {
                CronTrigger ct = cronTriggers[0];
                details.isScheduled = true;
                details.status = ct.State;
                details.nextRunTime = ct.NextFireTime;
                details.cronExpression = ct.CronExpression;
                
                LOGGER.info('Job is scheduled. Status: ' + ct.State + ', Next Run: ' + ct.NextFireTime + ', CRON: ' + ct.CronExpression);
            } else {
                details.isScheduled = false;
                LOGGER.info('Job is not scheduled for className: ' + jobName);
            }
        } catch (Exception e) {
            LOGGER.error('Error in getJobDetails for className: ' + jobName, e);
            throw new AuraHandledException('Error retrieving job details: ' + e.getMessage());
        }
        return details;
    }
    
    /**
     * Method to schedule a job.
     *
     * @param className The name of the Apex class to schedule.
     * @param cronExpression The CRON expression defining the schedule.
     * @return A success message upon successful scheduling.
     */
    @AuraEnabled
    public static String scheduleJob(String jobName, String className, String cronExpression) {
        LOGGER.info('scheduleJob called with jobName={0}, className={1}, CRON={2} ', new Object[]{jobName, className, cronExpression});
        try {
            Type jobType = Type.forName(className);
            if (jobType == null) {
                LOGGER.error('Apex class not found: ' + className);
                throw new AuraHandledException('Apex class not found.');
            }
            // Correct usage without casting
            if (!Schedulable.class.isAssignableFrom(jobType)) {
                LOGGER.error('Class does not implement Schedulable: ' + className);
                throw new AuraHandledException('The specified class does not implement Schedulable.');
            }
            System.schedule(jobName, cronExpression, (Schedulable)jobType.newInstance());
            LOGGER.info('Job scheduled successfully: ' + jobName);
            return 'Job scheduled successfully.';
        } catch (AuraHandledException ahe) {
            // Specific AuraHandledExceptions are already logged and handled
            throw ahe;
        } catch (Exception e) {
            LOGGER.error('Error scheduling job for className: ' + className + ', CRON: ' + cronExpression, e);
            throw new AuraHandledException('Error scheduling job: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for job details.
     */
    public class ScheduledJobDetails {
        @AuraEnabled public Boolean isScheduled { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Datetime nextRunTime { get; set; }
        @AuraEnabled public String cronExpression { get; set; }
    }
}
