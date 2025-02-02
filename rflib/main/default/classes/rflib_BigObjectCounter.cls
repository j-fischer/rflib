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
public with sharing class rflib_BigObjectCounter implements Database.Batchable<SObject> {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BigObjectCounter');

    @TestVisible
    private final String query;
    
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

    /**
     * Constructor to initialize the batch job with required parameters.
     * 
     * @param query                      The SOQL query string to execute against the Big Object
     * @param bigObjectType              The API name of the Big Object to count
     * @param targetObjectApiName        The API name of the object where the count will be stored
     * @param targetCounterFieldApiName  The API name of the field to store the count
     * @param targetLastUpdatedFieldApiName The API name of the field to store the last updated timestamp
     * @param currentCount               The current count of records (used for chaining batch jobs)
     */
    public rflib_BigObjectCounter(
        String query,
        String bigObjectType,
        String targetObjectApiName,
        String targetCounterFieldApiName,
        Integer currentCount
    ) {
        this.query = query;
        this.bigObjectType = bigObjectType;
        this.targetObjectApiName = targetObjectApiName;
        this.targetCounterFieldApiName = targetCounterFieldApiName;
        this.currentCount = currentCount;

        LOGGER.info('Initializing Big Object Counter for {0} with current count {1}', 
            new Object[] { bigObjectType, currentCount });
    }

    /**
     * Start method that returns the query locator for the batch execution.
     * 
     * @param bc The batch context
     * @return   Database.QueryLocator The query locator for batch processing
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            LOGGER.info('Starting batch job with query: {0}', new Object[] { query });
            return Database.getQueryLocator(query);
        } catch (Exception ex) {
            LOGGER.error('Failed to create query locator', ex);
            throw new rflib_BigObjectCounterException('Failed to create query locator: ' + ex.getMessage());
        }
    }

    /**
     * Execute method that processes each batch of records.
     * 
     * @param bc    The batch context
     * @param scope The list of SObject records to process
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            currentCount += scope.size();
            LOGGER.debug('Processed batch of {0} records. Current count: {1}', 
                new Object[] { scope.size(), currentCount });
        } catch (Exception ex) {
            LOGGER.error('Error processing batch', ex);
            throw new rflib_BigObjectCounterException('Error processing batch: ' + ex.getMessage());
        }
    }

    /**
     * Finish method that updates the target object with the final count and timestamp.
     * 
     * @param bc The batch context
     */
    public void finish(Database.BatchableContext bc) {
        try {
            String query = 'SELECT Id, ' + targetCounterFieldApiName + ', ' + 
                targetLastUpdatedFieldApiName + ' FROM ' + targetObjectApiName + 
                ' WHERE Name = :bigObjectType LIMIT 1';
            
            List<SObject> records = Database.query(query);
            if (records.isEmpty()) {
                LOGGER.error('No target record found for Big Object type: {0}', 
                    new Object[] { bigObjectType });
                throw new rflib_BigObjectCounterException(
                    'No target record found for Big Object type: ' + bigObjectType);
            }

            SObject record = records[0];
            record.put(targetCounterFieldApiName, currentCount);

            update record;

            LOGGER.info('Successfully updated count for {0}. Final count: {1}', 
                new Object[] { bigObjectType, currentCount });
        } catch (Exception ex) {
            LOGGER.error('Failed to update target record', ex);
            throw new rflib_BigObjectCounterException('Failed to update target record: ' + ex.getMessage());
        }
    }

    /**
     * Custom exception class for Big Object Counter specific errors.
     */
    public class rflib_BigObjectCounterException extends Exception {}
}