/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_ApexJobSchedulerController {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory()
        .createLogger('rflib_ApexJobSchedulerController');

    // The RFLIB jobs used by the Management Dashboard can always be scheduled or deleted. Admins who add the
    // component to their own pages allow further classes through the Ops_Center_Schedulable_Classes Global
    // Setting. Names are compared in lower case because Apex class names are case-insensitive.
    private static final Set<String> RFLIB_SCHEDULABLE_CLASSES = new Set<String>{
        rflib_ApplicationEventArchiver.class.getName().toLowerCase(),
        rflib_LogArchiveCleanup.class.getName().toLowerCase(),
        rflib_ApplicationEventArchiveCleanup.class.getName().toLowerCase()
    };

    private static final String ALLOW_CLASS_HINT =
        'To allow it, add the class name to the Ops_Center_Schedulable_Classes Global Setting.';

    @AuraEnabled(cacheable=true)
    public static ScheduledJobDetails getJobDetails(String jobName) {
        rflib_LoggerUtil.logInternal(LOGGER, 'getJobDetails called with jobName: ' + jobName);
        ScheduledJobDetails details = new ScheduledJobDetails();
        try {
            jobName = jobName.trim();
            
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

                rflib_LoggerUtil.logInternal(
                    LOGGER,
                    'Job is scheduled. Status: ' +
                        ct.State +
                        ', Next Run: ' +
                        ct.NextFireTime +
                        ', CRON: ' +
                        ct.CronExpression
                );
            } else {
                details.isScheduled = false;
                rflib_LoggerUtil.logInternal(LOGGER, 'Job is not scheduled for className: ' + jobName);
            }
        } catch (Exception e) {
            LOGGER.error('Error in getJobDetails for className: ' + jobName, e);
            throw rflib_ControllerUtil.createAuraHandledException('Error retrieving job details: ' + e.getMessage());
        }
        return details;
    }

    @AuraEnabled
    public static String scheduleJob(String jobName, String className, String cronExpression) {
        rflib_LoggerUtil.logInternal(
            LOGGER,
            'scheduleJob called with jobName={0}, className={1}, CRON={2} ',
            new List<Object>{ jobName, className, cronExpression }
        );
        try {
            jobName = jobName.trim();
            className = className.trim();
            cronExpression = cronExpression.trim();

            if (!isSchedulableClass(className)) {
                LOGGER.error('Apex class is not permitted to be scheduled: ' + className);
                throw rflib_ControllerUtil.createAuraHandledException(
                    'The class ' + className + ' cannot be scheduled from the Ops Center. ' + ALLOW_CLASS_HINT
                );
            }

            Type jobType = Type.forName(className);
            if (jobType == null) {
                LOGGER.error('Apex class not found: ' + className);
                throw rflib_ControllerUtil.createAuraHandledException('Apex class not found.');
            }
            // Correct usage without casting
            if (!Schedulable.class.isAssignableFrom(jobType)) {
                LOGGER.error('Class does not implement Schedulable: ' + className);
                throw rflib_ControllerUtil.createAuraHandledException(
                    'The specified class does not implement Schedulable.'
                );
            }
            System.schedule(jobName, cronExpression, (Schedulable) jobType.newInstance());
            rflib_LoggerUtil.logInternal(LOGGER, 'Job scheduled successfully: ' + jobName);
            return 'Job scheduled successfully.';
        } catch (AuraHandledException ahe) {
            // Specific AuraHandledExceptions are already logged and handled
            throw ahe;
        } catch (Exception e) {
            LOGGER.error('Error scheduling job for className: ' + className + ', CRON: ' + cronExpression, e);
            throw rflib_ControllerUtil.createAuraHandledException('Error scheduling job: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteScheduledJob(String jobName) {
        rflib_LoggerUtil.logInternal(LOGGER, 'deleteScheduledJob called with jobName: ' + jobName);
        try {
            jobName = jobName.trim();
            List<CronTrigger> cronTriggers = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
                LIMIT 1
            ];

            if (!cronTriggers.isEmpty()) {
                List<AsyncApexJob> scheduledApexJobs = [
                    SELECT ApexClass.Name, ApexClass.NamespacePrefix
                    FROM AsyncApexJob
                    WHERE CronTriggerId = :cronTriggers[0].Id AND JobType = 'ScheduledApex'
                    LIMIT 1
                ];
                String jobClassName = scheduledApexJobs.isEmpty() ? null : getFullClassName(scheduledApexJobs[0].ApexClass);
                if (!isDeletableJobClass(jobClassName)) {
                    LOGGER.error('Scheduled job is not permitted to be deleted: ' + jobName + ', class: ' + jobClassName);
                    throw rflib_ControllerUtil.createAuraHandledException(
                        'The job ' + jobName + ' runs the class ' + jobClassName + ' and cannot be deleted from the Ops Center. ' + ALLOW_CLASS_HINT
                    );
                }

                System.abortJob(cronTriggers[0].Id);
                rflib_LoggerUtil.logInternal(LOGGER, 'Job deleted successfully: ' + jobName);
            } else {
                LOGGER.error('No job found with name: ' + jobName);
                throw rflib_ControllerUtil.createAuraHandledException(
                    'No scheduled job found with the specified name.'
                );
            }
        } catch (Exception e) {
            LOGGER.error('Error deleting scheduled job for jobName: ' + jobName, e);
            throw rflib_ControllerUtil.createAuraHandledException('Error deleting scheduled job: ' + e.getMessage());
        }
    }

    private static String getFullClassName(ApexClass apexClass) {
        return String.isBlank(apexClass.NamespacePrefix) ? apexClass.Name : apexClass.NamespacePrefix + '.' + apexClass.Name;
    }

    private static Boolean isSchedulableClass(String className) {
        if (className == null) {
            return false;
        }

        if (RFLIB_SCHEDULABLE_CLASSES.contains(className.toLowerCase())) {
            return true;
        }

        for (String configuredClassName : rflib_GlobalSettings.opsCenterSchedulableClasses) {
            if (configuredClassName.equalsIgnoreCase(className)) {
                return true;
            }
        }
        return false;
    }

    // A scheduled job only records its top-level class, so a job running an inner class (Outer.Inner) is
    // matched against the configured name without its last segment as well.
    private static Boolean isDeletableJobClass(String topLevelClassName) {
        if (isSchedulableClass(topLevelClassName)) {
            return true;
        }

        for (String configuredClassName : rflib_GlobalSettings.opsCenterSchedulableClasses) {
            if (configuredClassName.substringBeforeLast('.').equalsIgnoreCase(topLevelClassName)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Wrapper class for job details.
     */
    public class ScheduledJobDetails {
        @AuraEnabled
        public Boolean isScheduled { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public Datetime nextRunTime { get; set; }
        @AuraEnabled
        public String cronExpression { get; set; }
    }
}
