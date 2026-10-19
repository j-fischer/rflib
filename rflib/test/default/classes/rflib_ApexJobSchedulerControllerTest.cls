/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_ApexJobSchedulerControllerTest {

    private static final String JOB_NAME = 'RFLIB Log Archive Cleanup Test';
    private static final String ALLOWED_CLASS_NAME = 'rflib_LogArchiveCleanup';
    private static final String CRON_EXPRESSION = '0 0 2 * * ?';

    private static final User OPS_CENTER_USER = rflib_TestUserFactory.insertWithPermissionSetAndRetrieve('Otto', 'SchedulerOps', 'Standard User', 'rflib_Ops_Center_Access');

    // Scheduled jobs only run when Test.stopTest() is called, which these tests avoid on purpose.
    public class NonRflibSchedulable implements Schedulable {
        public void execute(SchedulableContext context) {}
    }

    private static Integer countJobs(String jobName) {
        return [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
    }

    @IsTest
    private static void testScheduleJob_Success() {
        String result = rflib_ApexJobSchedulerController.scheduleJob(JOB_NAME, ALLOWED_CLASS_NAME, CRON_EXPRESSION);

        Assert.areEqual('Job scheduled successfully.', result, 'Job should be scheduled');
        rflib_ApexJobSchedulerController.ScheduledJobDetails details = rflib_ApexJobSchedulerController.getJobDetails(JOB_NAME);
        Assert.isTrue(details.isScheduled, 'Job should be reported as scheduled');
        Assert.areEqual(CRON_EXPRESSION, details.cronExpression, 'CRON expression should match');
    }

    @IsTest
    private static void testScheduleJob_ClassNameIsCaseInsensitive() {
        rflib_ApexJobSchedulerController.scheduleJob(JOB_NAME, ALLOWED_CLASS_NAME.toUpperCase(), CRON_EXPRESSION);

        Assert.areEqual(1, countJobs(JOB_NAME), 'Job should be scheduled');
    }

    @IsTest
    private static void testScheduleJob_OpsCenterUser() {
        System.runAs(OPS_CENTER_USER) {
            rflib_ApexJobSchedulerController.scheduleJob(JOB_NAME, ALLOWED_CLASS_NAME, CRON_EXPRESSION);
        }

        Assert.areEqual(1, countJobs(JOB_NAME), 'Ops Center user should be able to schedule an RFLIB job');
    }

    @IsTest
    private static void testScheduleJob_NonRflibClassIsRejected() {
        System.runAs(OPS_CENTER_USER) {
            try {
                rflib_ApexJobSchedulerController.scheduleJob(
                    JOB_NAME,
                    NonRflibSchedulable.class.getName(),
                    CRON_EXPRESSION
                );
                Assert.fail('Expected AuraHandledException was not thrown for a class that is not allowed.');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('cannot be scheduled from the Ops Center'), 'Exception message should indicate that the class is not allowed, was: ' + e.getMessage());
            }
        }

        Assert.areEqual(0, countJobs(JOB_NAME), 'Job should not be scheduled');
    }

    @IsTest
    private static void testScheduleJob_InvalidCronExpression() {
        try {
            rflib_ApexJobSchedulerController.scheduleJob(JOB_NAME, ALLOWED_CLASS_NAME, 'invalid');
            Assert.fail('Expected AuraHandledException was not thrown for an invalid CRON expression.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().startsWith('Error scheduling job: '), 'Exception message should indicate scheduling error, was: ' + e.getMessage());
        }
    }

    @IsTest
    private static void testGetJobDetails_NotScheduled() {
        rflib_ApexJobSchedulerController.ScheduledJobDetails details = rflib_ApexJobSchedulerController.getJobDetails(JOB_NAME);

        Assert.isFalse(details.isScheduled, 'Job should not be reported as scheduled');
    }

    @IsTest
    private static void testDeleteScheduledJob_Success() {
        System.schedule(JOB_NAME, CRON_EXPRESSION, new rflib_LogArchiveCleanup());

        System.runAs(OPS_CENTER_USER) {
            rflib_ApexJobSchedulerController.deleteScheduledJob(JOB_NAME);
        }

        Assert.areEqual(0, countJobs(JOB_NAME), 'Job should be deleted');
    }

    @IsTest
    private static void testDeleteScheduledJob_NonRflibJobIsRejected() {
        System.schedule(JOB_NAME, CRON_EXPRESSION, new NonRflibSchedulable());

        System.runAs(OPS_CENTER_USER) {
            try {
                rflib_ApexJobSchedulerController.deleteScheduledJob(JOB_NAME);
                Assert.fail('Expected AuraHandledException was not thrown for a job that is not allowed.');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('cannot be deleted from the Ops Center'), 'Exception message should indicate that the job is not allowed, was: ' + e.getMessage());
            }
        }

        Assert.areEqual(1, countJobs(JOB_NAME), 'Job should not be deleted');
    }

    @IsTest
    private static void testScheduleJob_ClassConfiguredInGlobalSetting() {
        rflib_GlobalSettings.SETTINGS.put('Ops_Center_Schedulable_Classes', 'SomeOtherJob, ' + NonRflibSchedulable.class.getName());

        System.runAs(OPS_CENTER_USER) {
            rflib_ApexJobSchedulerController.scheduleJob(JOB_NAME, NonRflibSchedulable.class.getName(), CRON_EXPRESSION);
        }

        Assert.areEqual(1, countJobs(JOB_NAME), 'Ops Center user should be able to schedule a class configured in the Global Setting');
    }

    @IsTest
    private static void testDeleteScheduledJob_ClassConfiguredInGlobalSetting() {
        rflib_GlobalSettings.SETTINGS.put('Ops_Center_Schedulable_Classes', NonRflibSchedulable.class.getName());
        System.schedule(JOB_NAME, CRON_EXPRESSION, new NonRflibSchedulable());

        System.runAs(OPS_CENTER_USER) {
            rflib_ApexJobSchedulerController.deleteScheduledJob(JOB_NAME);
        }

        Assert.areEqual(0, countJobs(JOB_NAME), 'Ops Center user should be able to delete a job running a class configured in the Global Setting');
    }

    @IsTest
    private static void testDeleteScheduledJob_NotFound() {
        try {
            rflib_ApexJobSchedulerController.deleteScheduledJob(JOB_NAME);
            Assert.fail('Expected AuraHandledException was not thrown for a job that does not exist.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('No scheduled job found with the specified name.'), 'Exception message should indicate that the job does not exist, was: ' + e.getMessage());
        }
    }
}
