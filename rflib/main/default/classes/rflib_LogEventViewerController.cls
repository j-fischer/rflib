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
public with sharing class rflib_LogEventViewerController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_LogEventViewerController');

    @TestVisible 
    private static rflib_QueryExecutor QUERY_EXECUTOR = new rflib_DatabaseQueryExecutor();

    @AuraEnabled(cacheable=true)
    public static List<ApexLogInfo> getApexLogsForRequestId(String requestId) {
        try {
            LOGGER.debug('getApexLogsForRequestId() invoked for request ID: ' + requestId);

            List<ApexLogInfo> result = new List<ApexLogInfo>();
            Integer index = 1;

            String query = 'SELECT Id, Status, Operation, DurationMilliseconds, StartTime, LastModifiedDate, LogLength, LogUserId, Request, Application ' +
                          'FROM ApexLog ' +
                          'WHERE RequestIdentifier = \'' + requestId + '\' ' +
                          'ORDER BY StartTime ASC';

            List<ApexLog> logs = (List<ApexLog>) QUERY_EXECUTOR.query(query);

            for (ApexLog log : logs) {
                result.add(new ApexLogInfo(
                    index++,
                    log.Id, 
                    log.Status,
                    log.Operation,
                    log.Application,
                    log.DurationMilliseconds, 
                    log.StartTime,
                    log.LastModifiedDate,
                    log.LogLength
                ));
            }

            LOGGER.debug('Found {0} ApexLog records for request ID {1}', new Object[] { result.size(), requestId });
            return result;
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve Apex Logs', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    public class ApexLogInfo {
        @AuraEnabled public Integer index { get; private set; }
        @AuraEnabled public String id { get; private set; }
        @AuraEnabled public String status { get; private set; }
        @AuraEnabled public String operation { get; private set; }
        @AuraEnabled public String application { get; private set; }
        @AuraEnabled public Integer durationMilliseconds { get; private set; }
        @AuraEnabled public DateTime startTime { get; private set; }
        @AuraEnabled public DateTime lastModifiedDate { get; private set; }
        @AuraEnabled public Integer logLength { get; private set; }
        @AuraEnabled public String menuLabel { get; private set; }
        @AuraEnabled public String menuTitle { get; private set; }

        public ApexLogInfo(
            Integer index,
            String id, 
            String status,
            String operation,
            String application,
            Integer durationMilliseconds, 
            DateTime startTime,
            DateTime lastModifiedDate, 
            Integer logLength
        ) {
            this.index = index;
            this.id = id;
            this.status = status;
            this.operation = operation;
            this.application = application;
            this.durationMilliseconds = durationMilliseconds;
            this.startTime = startTime;
            this.lastModifiedDate = lastModifiedDate;
            this.logLength = logLength;

            this.menuLabel = String.format('Apex Debug Log {0}', new List<String>{String.valueOf(index)});
            
            String timeStr = startTime == null ? 'N/A' : startTime.format('HH:mm:ss.SSS');
            String sizeInKb = logLength == null ? 'N/A' : String.valueOf(Math.round(logLength / 1024.0));
            String durationMs = durationMilliseconds == null ? 'N/A' : String.valueOf(durationMilliseconds);

            this.menuTitle = String.format('Start Time: {0}\nOperation: {1}\nApplication: {2}\nSize: {3}KB\nDuration: {4}ms', 
                new List<String>{
                    timeStr,
                    String.isBlank(operation) ? 'N/A' : operation,
                    String.isBlank(application) ? 'N/A' : application,
                    sizeInKb,
                    durationMs
                }
            );
        }
    }
}