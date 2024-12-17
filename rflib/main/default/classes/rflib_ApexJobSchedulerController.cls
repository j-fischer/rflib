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

    @AuraEnabled(cacheable=true)
    public static ScheduledJobDetails getJobDetails(String jobName) {
        rflib_LoggerUtil.logInternal(LOGGER, 'getJobDetails called with jobName: ' + jobName);
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
            List<CronTrigger> cronTriggers = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
                LIMIT 1
            ];

            if (!cronTriggers.isEmpty()) {
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
