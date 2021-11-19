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
public with sharing class rflib_LogArchiveController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_LogArchiveController');
    
    @TestVisible
    private static ILogArchiveQueryLocator QUERY_LOCATOR = new DefaultLogArchiveQueryLocator();
    
    @TestVisible
    private static rflib_DmlExecutor DML_EXECUTOR = new rflib_DatabaseDmlExecutor();

    @AuraEnabled
    public static List<rflib_Logs_Archive__b> getArchivedRecords(Datetime startDate, Datetime endDate) {
        try {
            Datetime startDateOrDefault = startDate != null ? startDate : Datetime.now().addDays(-1);
            Datetime endDateOrDefault = endDate != null ? endDate : Datetime.now();
            
            return QUERY_LOCATOR.getRecords(startDateOrDefault, endDateOrDefault);
        } catch (Exception ex) {
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void clearArchive() {
        try {
            List<rflib_Logs_Archive__b> records = new List<rflib_Logs_Archive__b>();
            records.addAll(QUERY_LOCATOR.getOldestRecords());
            
            DML_EXECUTOR.deleteImmediate(records);
        } catch (Exception ex) {
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    public interface ILogArchiveQueryLocator {
        List<rflib_Logs_Archive__b> getRecords(Datetime startDate, Datetime endDate);
        List<rflib_Logs_Archive__b> getOldestRecords();
    }

    public class DefaultLogArchiveQueryLocator implements ILogArchiveQueryLocator {

        public List<rflib_Logs_Archive__b> getRecords(Datetime startDate, Datetime endDate) {
            return [
                SELECT CreatedDate__c, CreatedById__c, Context__c, Log_Level__c, Request_ID__c, Log_Messages__c 
                FROM rflib_Logs_Archive__b
                WHERE CreatedDate__c > :startDate
                AND CreatedDate__c < :endDate
                LIMIT 50000
            ];
        }

        public List<rflib_Logs_Archive__b> getOldestRecords() {
            return [
                SELECT CreatedDate__c, Context__c, Log_Level__c, Request_ID__c 
                FROM rflib_Logs_Archive__b 
                ORDER BY CreatedDate__c ASC 
                LIMIT 50000
            ];
        }
    }
}
