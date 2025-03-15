/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
public virtual with sharing class rflib_LogArchiveCleanup implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_LogArchiveCleanup');
    
    // Constants are now managed in rflib_GlobalSettings
    
    @TestVisible
    private static rflib_DmlExecutor DML_EXECUTOR = new rflib_DatabaseDmlExecutor();
    
    @TestVisible
    private final Datetime referenceDate;
    private final Datetime lastProcessedDate;
    
    private Integer totalProcessed = 0;
    
    public rflib_LogArchiveCleanup() {
        this(null, null);
    }
    
    private rflib_LogArchiveCleanup(Datetime lastProcessedDate, Integer totalProcessed) {
        // Normalize the reference date to start of day
        Date today = Date.today();
        Date cutoffDate = today.addDays((-1) * rflib_GlobalSettings.daysToRetainArchivedLogsOrDefault);
        this.referenceDate = Datetime.newInstance(cutoffDate, Time.newInstance(0, 0, 0, 0));
        
        this.lastProcessedDate = lastProcessedDate;
        if (totalProcessed != null) {
            this.totalProcessed = totalProcessed;
        }
        
        LOGGER.info('Initialized cleanup with referenceDate={0}, lastProcessedDate={1}, totalProcessed={2}', 
            new Object[] { referenceDate, lastProcessedDate, this.totalProcessed });
    }
    
    public void execute(SchedulableContext sc) {
        try {
            LOGGER.info('Starting scheduled cleanup of log archives');
            Database.executeBatch(this, rflib_GlobalSettings.logArchiveCleanupBatchSizeOrDefault);
        } catch (Exception ex) {
            LOGGER.fatal('Failed to execute scheduled cleanup', ex);
        }
    }
    
    public Iterable<SObject> start(Database.BatchableContext bc) {
        rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup
            .add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).lessThan(referenceDate));

        if (lastProcessedDate != null) {
            filterGroup.add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).greaterThan(lastProcessedDate));
        }        

        rflib_SOQL query = rflib_SOQL.of(rflib_Logs_Archive__b.SObjectType)
            .with(new List<SObjectField>{
                rflib_Logs_Archive__b.CreatedDate__c,
                rflib_Logs_Archive__b.Context__c,
                rflib_Logs_Archive__b.Log_Level__c,
                rflib_Logs_Archive__b.Request_ID__c
            })
            .whereAre(filterGroup)
            .orderBy(rflib_Logs_Archive__b.CreatedDate__c)
            .setLimit(rflib_GlobalSettings.logArchiveCleanupQueryLimitOrDefault)
            .systemMode()
            .mockId('LogArchiveCleanup.start');
            
        List<SObject> records = query.toList();            
        LOGGER.info('Starting batch processing {0} records older than {2} with query: {1}', new Object[] { records.size(), query.toString(), referenceDate });
        return records;
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            if (scope.isEmpty()) {
                return;
            }
            
            LOGGER.debug('Processing {0} records for deletion', new Object[] { scope.size() });
            List<Database.DeleteResult> results = DML_EXECUTOR.deleteImmediate(scope);
            
            Integer successCount = 0;
            for (Database.DeleteResult dr : results) {
                if (dr.isSuccess()) {
                    successCount++;
                } else {
                    LOGGER.warn('Failed to delete record: {0}', new Object[] { dr.getErrors() });
                }
            }
            
            totalProcessed += successCount;
            LOGGER.info('Successfully deleted {0} records. Total processed: {1}', 
                new Object[] { successCount, totalProcessed });
            
        } catch (Exception ex) {
            LOGGER.error('Failed to process batch', ex);
            throw new rflib_LogArchiveCleanupException('Batch processing failed: ' + ex.getMessage());
        }
    }
    
    protected virtual void chainNextBatch(Datetime referenceDate, Integer totalProcessed) {
        Database.executeBatch(
            new rflib_LogArchiveCleanup(
                referenceDate, 
                totalProcessed
            ), 
            rflib_GlobalSettings.logArchiveCleanupBatchSizeOrDefault
        );
    }

    public void finish(Database.BatchableContext bc) {
        try {
            LOGGER.info('Finished batch processing. Total records processed: {0}', new Object[] { totalProcessed });
            
            if (totalProcessed > 0 && Math.mod(totalProcessed, rflib_GlobalSettings.logArchiveCleanupQueryLimitOrDefault) == 0) {
                LOGGER.info('Chaining next batch as batch size limit was hit');
                chainNextBatch(referenceDate, totalProcessed);
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to finish batch', ex);
            throw new rflib_LogArchiveCleanupException('Batch finish failed: ' + ex.getMessage());
        }
    }
    
    public class rflib_LogArchiveCleanupException extends Exception {}
}