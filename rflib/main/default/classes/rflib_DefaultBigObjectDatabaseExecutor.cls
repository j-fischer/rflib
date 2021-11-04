/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
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
public class rflib_DefaultBigObjectDatabaseExecutor implements rflib_BigObjectDatabaseExecutor {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('rflib_DefaultBigObjectDatabaseExecutor');
    
    public static Integer NUM_RETRIES = 3;

    private final rflib_DmlExecutor db;

    public rflib_DefaultBigObjectDatabaseExecutor() {
        this(new rflib_DatabaseDmlExecutor());
    }

    @TestVisible
    private rflib_DefaultBigObjectDatabaseExecutor(rflib_DmlExecutor dmlExecutor) {
        db = dmlExecutor;
    }

    public void insertImmediate(List<SObject> records) {
        // See https://developer.salesforce.com/docs/atlas.en-us.bigobjects.meta/bigobjects/big_object_considerations.htm
        new BigObjectDatabaseInsertQueueable(db, records, NUM_RETRIES).execute(null);
    }

    private class BigObjectDatabaseInsertQueueable implements Queueable {

        private final rflib_DmlExecutor db;
        private final List<SObject> recordsToInsert;
        private final Integer numRetries;
        
        public BigObjectDatabaseInsertQueueable(rflib_DmlExecutor dmlExecutor, List<SObject> recordsToInsert, Integer numRetries) {
            db = dmlExecutor;
            this.recordsToInsert = recordsToInsert;
            this.numRetries = numRetries;
        }

        public void execute(QueueableContext ctx) {
            Database.SaveResult[] results = db.insertImmediate(recordsToInsert);
            Boolean shouldRetry = false;
            for (Database.SaveResult res : results) {
                if (!res.isSuccess()) {
                    LOGGER.trace('Failed to insert big object: ' + res.getErrors());
                    shouldRetry = true;
                }
            }

            if (numRetries > 0 && shouldRetry) {
                System.enqueueJob(new BigObjectDatabaseInsertQueueable(db, recordsToInsert, numRetries - 1));
            }
        }
    }
}
