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
public abstract class rflib_AbstractArchiveCleanup {
    
    @TestVisible
    protected rflib_DmlExecutor dmlExecutor = new rflib_DatabaseDmlExecutor();
    
    @TestVisible
    protected final Datetime referenceDate;
    protected final Datetime lastProcessedDate;
    
    protected Integer totalProcessed = 0;
    protected final rflib_Logger logger;
    
    protected rflib_AbstractArchiveCleanup(rflib_Logger logger, Integer daysToRetain, Datetime lastProcessedDate, Integer totalProcessed) {
        this.logger = logger;
        
        // Normalize the reference date to start of day
        Date today = Date.today();
        Date cutoffDate = today.addDays((-1) * daysToRetain);
        this.referenceDate = Datetime.newInstance(cutoffDate, Time.newInstance(0, 0, 0, 0));
        
        this.lastProcessedDate = lastProcessedDate;
        if (totalProcessed != null) {
            this.totalProcessed = totalProcessed;
        }
        
        logger.info('Initialized cleanup with referenceDate={0}, lastProcessedDate={1}, totalProcessed={2}', 
            new Object[] { referenceDate, lastProcessedDate, this.totalProcessed });
    }
    
    public abstract Iterable<SObject> start(Database.BatchableContext bc);
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            if (scope.isEmpty()) {
                return;
            }
            
            logger.debug('Processing {0} records for deletion', new Object[] { scope.size() });
            // Use the static test executor if provided, otherwise use the instance executor
            List<Database.DeleteResult> results = dmlExecutor.deleteImmediate(scope);
            
            Integer successCount = 0;
            for (Database.DeleteResult dr : results) {
                if (dr.isSuccess()) {
                    successCount++;
                } else {
                    logger.warn('Failed to delete record: {0}', new Object[] { dr.getErrors() });
                }
            }
            
            totalProcessed += successCount;
            logger.info('Successfully deleted {0} records. Total processed: {1}', 
                new Object[] { successCount, totalProcessed });
            
        } catch (Exception ex) {
            logger.error('Failed to process batch', ex);
            throw new rflib_ArchiveCleanupException('Batch processing failed: ' + ex.getMessage());
        }
    }
    
    protected virtual void chainNextBatch(Datetime lastProcessedDate, Integer totalProcessed) {
        // Default implementation does nothing, to be overridden by subclasses
    }
    
    protected abstract Integer getBatchSize();
    
    protected abstract Integer getQueryLimit();
    
    public void finish(Database.BatchableContext bc) {
        try {
            logger.info('Finished batch processing. Total records processed: {0}', new Object[] { totalProcessed });
            
            if (totalProcessed > 0 && Math.mod(totalProcessed, getQueryLimit()) == 0) {
                logger.info('Chaining next batch as batch size limit was hit');
                chainNextBatch(referenceDate, totalProcessed);
            }
        } catch (Exception ex) {
            logger.error('Failed to finish batch', ex);
            throw new rflib_ArchiveCleanupException('Batch finish failed: ' + ex.getMessage());
        }
    }
    
    public class rflib_ArchiveCleanupException extends Exception {}
}