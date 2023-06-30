String jobName = 'RFLIB Application Event Archiver';
String cronExpression = '0 0 * * * ?'; // Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year => Default '0 0 3 ? * 0#2'

List<CronJobDetail> cronDetails = [SELECT Id FROM CronJobDetail WHERE Name = :jobName LIMIT 1];

List<CronTrigger> existingTriggers = cronDetails.isEmpty() ? 
    new List<CronTrigger>() :
    [SELECT Id FROM CronTrigger WHERE CronJobDetailId = :cronDetails[0].Id];

if (!existingTriggers.isEmpty()) {
    for (CronTrigger ct : existingTriggers) {
        System.abortJob(ct.Id);
    }
}
System.schedule(jobName, cronExpression, new rflib_ApplicationEventArchiver());