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
@SuppressWarnings('PMD.ClassNamingConventions,PMD.EmptyCatchBlock')
public with sharing class rflib_BigObjectCounter implements Database.Batchable<SObject>, Database.Stateful {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BigObjectCounter');
    
    @TestVisible
    private final String bigObjectType;
    
    @TestVisible
    private final String targetObjectApiName;
    
    @TestVisible
    private final String targetCounterFieldApiName;
    
    @TestVisible
    private final String targetLastUpdatedFieldApiName;
    
    @TestVisible
    private Integer currentCount;
    
    // Record count at the start of this batch job (used to determine page size)
    private Integer startingCount;
    
    // Pagination parameters: the last primary index field value processed and a set of compound keys for that value.
    private String lastIndex1Value;
    private Set<String> lastCompoundKeys;
    
    // Flag to indicate whether this is the initial batch (i.e. no pagination parameters yet)
    private final Boolean isInitialBatch;
    
    // The page size and index fields are now passed into the constructor.
    private final Integer pageSize;
    private final List<String> indexFields;
    
    /**
     * Constructor to initialize the batch job with required parameters.
     * 
     * @param bigObjectType              The API name of the Big Object to count
     * @param targetObjectApiName        The API name of the object where the count will be stored
     * @param targetCounterFieldApiName  The API name of the field to store the count
     * @param currentCount               The current count of records (used for chaining batch jobs)
     * @param lastIndex1Value            The last primary index field value processed (null for initial batch)
     * @param lastCompoundKeys           The compound keys corresponding to lastIndex1Value (null for initial batch)
     * @param pageSize                   The number of records to query per batch page
     * @param indexFields                The list of index fields that form the compound key (first element is primary)
     */
    public rflib_BigObjectCounter(
        String bigObjectType,
        String targetObjectApiName,
        String targetCounterFieldApiName,
        Integer currentCount,
        String lastIndex1Value,
        Set<String> lastCompoundKeys,
        Integer pageSize,
        List<String> indexFields
    ) {
        this.bigObjectType = bigObjectType;
        this.targetObjectApiName = targetObjectApiName;
        this.targetCounterFieldApiName = targetCounterFieldApiName;
        this.targetLastUpdatedFieldApiName = null;  // Not used in this sample but can be assigned as needed.
        this.currentCount = currentCount ?? 0;
        this.startingCount = currentCount ?? 0;
        this.lastIndex1Value = lastIndex1Value;
        this.lastCompoundKeys = lastCompoundKeys ?? new Set<String>();
        this.pageSize = pageSize ?? 50000;
        this.indexFields = indexFields;
        this.isInitialBatch = (lastIndex1Value == null);
        
        LOGGER.info('Initializing Big Object Counter for {0} with current count {1}. LastIndex1Value: {2}', 
            new Object[] { bigObjectType, currentCount, lastIndex1Value });
    }
    
    /**
     * Builds the dynamic SOQL query for the Big Object based on pagination.
     */
    private String buildQuery() {
        String baseQuery = 'SELECT ';
        // Add all index fields used to build the compound key.
        baseQuery += String.join(indexFields, ', ');
        baseQuery += ' FROM ' + bigObjectType;
        
        // For chained batches, filter on the primary index field.
        if (!isInitialBatch) {
            baseQuery += ' WHERE ' + indexFields[0] + ' >= \'' + String.escapeSingleQuotes(lastIndex1Value) + '\'';
        }
        
        baseQuery += ' ORDER BY ' + indexFields[0] + ' ASC';
        baseQuery += ' LIMIT ' + pageSize;
        
        return baseQuery;
    }
    
    /**
     * Creates a compound key string from the record's index fields.
     */
    private String buildCompoundKey(SObject record) {
        List<String> keyParts = new List<String>();
        for (String field : indexFields) {
            keyParts.add(String.valueOf(record.get(field)));
        }
        return String.join(keyParts, '||');
    }
    
    /**
     * Start method that returns an Iterable for processing a subset of Big Object records.
     */
    public Iterable<SObject> start(Database.BatchableContext bc) {
        String query = buildQuery();

        LOGGER.info('Starting batch job with query: {0}', new Object[] { query });
        return Database.query(query);
    }
    
    /**
     * Execute method that processes each batch (chunk) of records.
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            currentCount += scope.size();
            // Iterate through each record to update pagination tracking.
            for (SObject rec : scope) {
                String currentIndex = String.valueOf(rec.get(indexFields[0]));
                // When a new primary index value is encountered, reset the compound key tracker.
                if (lastIndex1Value == null || currentIndex.compareTo(lastIndex1Value) > 0) {
                    lastIndex1Value = currentIndex;
                    lastCompoundKeys = new Set<String>();
                }
                // For records matching the current last primary index value, add their compound key.
                if (String.valueOf(rec.get(indexFields[0])) == lastIndex1Value) {
                    String compoundKey = buildCompoundKey(rec);
                    lastCompoundKeys.add(compoundKey);
                }
            }
            LOGGER.info('Processed batch of {0} records. Current count: {1}', 
                new Object[] { scope.size(), currentCount });
        } catch (Exception ex) {
            LOGGER.error('Error processing batch', ex);
            throw new rflib_BigObjectCounterException('Error processing batch: ' + ex.getMessage());
        }
    }
    
    /**
     * Finish method that updates the target record with the final count and chains the next batch job if needed.
     */
    public void finish(Database.BatchableContext bc) {
        try {
            LOGGER.info('Finishing batch job. Current count: {0}', new Object[] { currentCount });

            // Update or create the target record with the final count.
            String targetQuery = 'SELECT Id, ' + targetCounterFieldApiName + 
                ' FROM ' + targetObjectApiName + 
                ' WHERE Name = \'' + String.escapeSingleQuotes(bigObjectType) + '\' LIMIT 1';
            
            List<SObject> records = Database.query(targetQuery);
            SObject record;
            
            if (records.isEmpty()) {
                record = Schema.getGlobalDescribe().get(targetObjectApiName).newSObject();
                record.put('Name', bigObjectType);
                record.put(targetCounterFieldApiName, currentCount);
                insert record;
                
                LOGGER.info('Created new record for {0} with count: {1}', 
                    new Object[] { bigObjectType, currentCount });
            } else {
                record = records[0];
                record.put(targetCounterFieldApiName, currentCount);
                update record;
                
                LOGGER.info('Updated count for {0}. Final count: {1}', 
                    new Object[] { bigObjectType, currentCount });
            }
            
            // Determine the number of records processed in this batch page.
            Integer pageCount = currentCount - startingCount;
            // If we received a full page, schedule the next batch job.
            if (pageCount == pageSize) {
                LOGGER.info('Scheduling next batch job. Next query will start from primary index value: {0}', 
                    new Object[] { lastIndex1Value });
                Database.executeBatch(
                    new rflib_BigObjectCounter(
                        bigObjectType, 
                        targetObjectApiName, 
                        targetCounterFieldApiName, 
                        currentCount,
                        lastIndex1Value,
                        lastCompoundKeys,
                        pageSize,
                        indexFields
                    )
                );
            } else {
                LOGGER.info('Batch processing complete. Total count: {0}', new Object[] { currentCount });
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to update target record or chain next batch', ex);
            throw new rflib_BigObjectCounterException('Failed in finish: ' + ex.getMessage());
        }
    }
    
    /**
     * Custom exception class for Big Object Counter specific errors.
     */
    public class rflib_BigObjectCounterException extends Exception {}
}
