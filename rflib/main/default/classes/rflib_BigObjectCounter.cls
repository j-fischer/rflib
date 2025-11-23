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
@SuppressWarnings('PMD.ClassNamingConventions,PMD.EmptyCatchBlock')
public with sharing class rflib_BigObjectCounter implements Database.Batchable<SObject>, Database.Stateful {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BigObjectCounter');
    
    private static final String COMPOUND_KEY_SEPARATOR = '||';
    private static final String KEY_LIST_SEPARATOR = ';';
    private static final Integer DEFAULT_PAGE_SIZE = 50000;
    
    // Configuration properties
    private final String bigObjectType;
    private final String targetObjectApiName;
    private final String targetCounterFieldApiName;
    private final Integer pageSize;
    private final List<String> indexFields;
    private final String orderBy;
    
    // State tracking
    private final Boolean isInitialBatch;
    private Integer currentCount;
    private Integer startingCount;
    private Object lastIndex1Value;
    private String lastCompoundKeys;

    public rflib_BigObjectCounter(
        String bigObjectType,
        String targetObjectApiName,
        String targetCounterFieldApiName,
        Integer currentCount,
        Object lastIndex1Value,
        String lastCompoundKeys,
        Integer pageSize,
        List<String> indexFields,
        String orderBy
    ) {
        this.validateInputs(bigObjectType, targetObjectApiName, targetCounterFieldApiName, indexFields);
        
        this.bigObjectType = bigObjectType;
        this.targetObjectApiName = targetObjectApiName;
        this.targetCounterFieldApiName = targetCounterFieldApiName;
        this.currentCount = currentCount ?? 0;
        this.startingCount = this.currentCount;
        this.lastIndex1Value = lastIndex1Value;
        this.lastCompoundKeys = String.isBlank(lastCompoundKeys) ? '' : lastCompoundKeys;
        this.pageSize = (pageSize == null || pageSize <= 0) ? DEFAULT_PAGE_SIZE : pageSize;
        this.indexFields = indexFields;
        this.orderBy = String.isBlank(orderBy) ? 'ASC' : orderBy.toUpperCase();
        
        this.isInitialBatch = (lastIndex1Value == null);
        
        LOGGER.info('Initialized counter for {0}: currentCount={1}, lastIndex={2}', 
            new Object[] { bigObjectType, this.currentCount, lastIndex1Value });
    }
    
    public Iterable<SObject> start(Database.BatchableContext bc) {
        rflib_SOQL.Queryable query = buildQuery();
        LOGGER.info('Starting batch with jobId "{0}" and query: {1}', new Object[] { bc.getJobId(), query.toString() });
        return query.toList();
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            LOGGER.info('Processing batch with jobId "{0}" and {1} records', new Object[] { bc.getJobId(), scope.size() });
            this.processRecords(scope);
        } catch (Exception ex) {
            LOGGER.error('Batch processing error', ex);
            throw new rflib_BigObjectCounterException('Batch processing failed: ' + ex.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        try {
            LOGGER.info('Finishing batch with jobId "{0}"', new Object[] { bc.getJobId() });
            this.updateTargetRecord();
            this.chainNextBatchIfNeeded();
        } catch (Exception ex) {
            LOGGER.error('Finish processing error', ex);
            throw new rflib_BigObjectCounterException('Finish processing failed: ' + ex.getMessage());
        }
    }
    
    private void validateInputs(String bigObjectType, String targetObjectApiName, 
        String targetCounterFieldApiName, List<String> indexFields) {
        if (String.isBlank(bigObjectType)) throw new rflib_BigObjectCounterException('Big Object Type cannot be blank');
        if (String.isBlank(targetObjectApiName)) throw new rflib_BigObjectCounterException('Target Object API Name cannot be blank');
        if (String.isBlank(targetCounterFieldApiName)) throw new rflib_BigObjectCounterException('Target Counter Field cannot be blank');
        if (indexFields == null || indexFields.isEmpty()) throw new rflib_BigObjectCounterException('Index Fields cannot be empty');
    }
    
    private rflib_SOQL.Queryable buildQuery() {
        rflib_SOQL.Queryable query = rflib_SOQL.of(bigObjectType).with(indexFields);
        
        if (!isInitialBatch) {
            query.whereAre(rflib_SOQL.Filter.with(indexFields[0]).greaterOrEqual(lastIndex1Value));
        }
        
        return query.orderBy(indexFields[0], orderBy)
            .setLimit(pageSize)
            .systemMode()
            .mockId('rflib_BigObjectCounter.query');
    }
    
    private void processRecords(List<SObject> scope) {
        LOGGER.info('Processing {0} records', new Object[] { scope.size() });
        
        for (SObject record : scope) {
            Object currentIndex1Val = record.get(indexFields[0]);
            String compoundKey = this.buildCompoundKey(record);
            
            if (!this.isRecordAlreadyCounted(compoundKey)) {
                this.updateCounters(currentIndex1Val, compoundKey);
            }
        }
    }
    
    private String buildCompoundKey(SObject record) {
        List<String> keyParts = new List<String>();
        for (String field : indexFields) {
            keyParts.add(String.valueOf(record.get(field)));
        }
        return String.join(keyParts, COMPOUND_KEY_SEPARATOR);
    }
    
    private Boolean isRecordAlreadyCounted(String compoundKey) {
        return lastCompoundKeys.contains(compoundKey);
    }
    
    private void updateCounters(Object currentIndex1Val, String compoundKey) {
        currentCount++;
        
        if (lastIndex1Value == null || currentIndex1Val != lastIndex1Value) {
            lastIndex1Value = currentIndex1Val;
            lastCompoundKeys = compoundKey;
        } else {
            lastCompoundKeys += KEY_LIST_SEPARATOR + compoundKey;
        }
    }
    
    private void updateTargetRecord() {
        SObject record = this.getOrCreateTargetRecord();
        record.put(targetCounterFieldApiName, currentCount);
        
        Database.upsert(record);
        LOGGER.info('Updated count for {0}: {1}', new Object[] { bigObjectType, currentCount });
    }
    
    private SObject getOrCreateTargetRecord() {
        List<SObject> records = rflib_SOQL.of(targetObjectApiName)
            .with(new List<String>{ 'Id', targetCounterFieldApiName })
            .whereAre(rflib_SOQL.Filter.with('Name').equal(bigObjectType))
            .setLimit(1)
            .systemMode()
            .toList();
            
        if (records.isEmpty()) {
            SObject newRecord = Schema.getGlobalDescribe().get(targetObjectApiName).newSObject();
            newRecord.put('Name', bigObjectType);
            return newRecord;
        }
        
        return records[0];
    }
    
    private void chainNextBatchIfNeeded() {
        Integer pageCount = currentCount - startingCount;
        if (pageCount == pageSize) {
            LOGGER.info('Chaining next batch from index: {0}', new Object[] { lastIndex1Value });
            Database.executeBatch(this.createNextBatch());
        }
    }
    
    private Database.Batchable<SObject> createNextBatch() {
        return new rflib_BigObjectCounter(
            bigObjectType, 
            targetObjectApiName, 
            targetCounterFieldApiName, 
            currentCount,
            lastIndex1Value,
            lastCompoundKeys,
            pageSize,
            indexFields,
            orderBy
        );
    }
    
    public class rflib_BigObjectCounterException extends Exception {}
}
