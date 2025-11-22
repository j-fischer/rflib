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
public virtual with sharing class rflib_LogArchiveCleanup extends rflib_AbstractArchiveCleanup implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_LogArchiveCleanup');

    @TestVisible
    private static final rflib_SOQL.Queryable QUERY = rflib_SOQL.of(rflib_Logs_Archive__b.SObjectType)
        .with(new List<SObjectField>{
            rflib_Logs_Archive__b.CreatedDate__c,
            rflib_Logs_Archive__b.Context__c,
            rflib_Logs_Archive__b.Log_Level__c,
            rflib_Logs_Archive__b.Request_ID__c
        })
        .orderBy(rflib_Logs_Archive__b.CreatedDate__c)
        .systemMode()
        .mockId('LogArchiveCleanup.start');
    
    public rflib_LogArchiveCleanup() {
        this(null, null);
    }
    
    private rflib_LogArchiveCleanup(Datetime lastProcessedDate, Integer totalProcessed) {
        super(LOGGER, rflib_GlobalSettings.daysToRetainArchivedLogsOrDefault, lastProcessedDate, totalProcessed);
    }

    public void execute(SchedulableContext sc) {
        try {
            logger.info('Starting scheduled cleanup');
            Database.executeBatch(this, getBatchSize());
        } catch (Exception ex) {
            logger.fatal('Failed to execute scheduled cleanup', ex);
        }
    }
    
    public override Iterable<SObject> start(Database.BatchableContext bc) {
        rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup
            .add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).lessThan(referenceDate));

        if (lastProcessedDate != null) {
            filterGroup.add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).greaterThan(lastProcessedDate));
        }        

        QUERY.whereAre(filterGroup).setLimit(getQueryLimit());
            
        List<SObject> records = QUERY.toList();            
        logger.info('Starting batch processing {0} records older than {2} with query: {1}', 
            new Object[] { records.size(), QUERY.toString(), referenceDate });
            
        return records;
    }
    
    protected override void chainNextBatch(Datetime lastProcessedDate, Integer totalProcessed) {
        Database.executeBatch(
            new rflib_LogArchiveCleanup(
                lastProcessedDate, 
                totalProcessed
            ), 
            getBatchSize()
        );
    }
    
    protected override Integer getBatchSize() {
        return rflib_GlobalSettings.logArchiveCleanupBatchSizeOrDefault;
    }
    
    protected override Integer getQueryLimit() {
        return rflib_GlobalSettings.logArchiveCleanupQueryLimitOrDefault;
    }
    
    public class rflib_LogArchiveCleanupException extends Exception {}
}