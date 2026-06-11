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
    private static Integer ARCHIVE_LOG_QUERY_LIMIT = rflib_GlobalSettings.archiveLogQueryLimitOrDefault;

    @TestVisible
    private static ILogArchiveQueryLocator QUERY_LOCATOR = new DefaultLogArchiveQueryLocator();

    @TestVisible
    private static rflib_DmlExecutor DML_EXECUTOR = new rflib_DatabaseDmlExecutor();

    @AuraEnabled
    public static ArchiveQueryResult getArchivedRecords(Datetime startDate, Datetime endDate) {
        try {
            LOGGER.debug('getArchivedRecords({0}, {1})', new List<Object>{ startDate, endDate });
            Datetime startDateOrDefault = startDate != null ? startDate : Datetime.now().addDays(-1);
            Datetime endDateOrDefault = endDate != null ? endDate : Datetime.now();

            return new ArchiveQueryResult(
                ARCHIVE_LOG_QUERY_LIMIT,
                QUERY_LOCATOR.getRecords(startDateOrDefault, endDateOrDefault)
            );
        } catch (Exception ex) {
            LOGGER.error('Failed to query rflib_Logs_Archive__b', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static LogSummaryResult getRecentLogSummary(Integer lookbackHours, String logLevels) {
        try {
            LOGGER.debug('getRecentLogSummary({0}, {1})', new List<Object>{ lookbackHours, logLevels });

            Integer hours = (lookbackHours != null && lookbackHours > 0) ? lookbackHours : 24;
            Set<String> levels = parseLevels(logLevels);

            Datetime startDate = Datetime.now().addHours((-1) * hours);
            Datetime endDate = Datetime.now();

            List<rflib_Logs_Archive__b> records = QUERY_LOCATOR.getRecordSummaries(startDate, endDate);

            Map<String, Integer> counts = new Map<String, Integer>();
            for (String level : levels) {
                counts.put(level, 0);
            }

            for (rflib_Logs_Archive__b record : records) {
                String level = record.Log_Level__c != null ? record.Log_Level__c.toUpperCase() : null;
                if (level != null && counts.containsKey(level)) {
                    counts.put(level, counts.get(level) + 1);
                }
            }

            // The query is capped at the Big Object synchronous maximum and cannot filter by level. When the
            // window fills that cap, severe records may exist beyond the returned slice, so flag the result as
            // truncated - the LWC surfaces an advisory rather than a potentially false "all clear".
            Boolean truncated = records.size() >= ARCHIVE_LOG_QUERY_LIMIT;

            return new LogSummaryResult(hours, counts, truncated);
        } catch (Exception ex) {
            LOGGER.error('Failed to summarize rflib_Logs_Archive__b', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    private static Set<String> parseLevels(String logLevels) {
        Set<String> levels = new Set<String>();
        String raw = String.isNotBlank(logLevels) ? logLevels : 'WARN,ERROR,FATAL';
        for (String part : raw.split(',')) {
            if (String.isNotBlank(part)) {
                levels.add(part.trim().toUpperCase());
            }
        }
        return levels;
    }

    @AuraEnabled
    public static Integer clearArchive() {
        try {
            LOGGER.debug('clearArchive()');

            Datetime referenceDate = Datetime.now()
                .addDays((-1) * rflib_GlobalSettings.daysToRetainArchivedLogsOrDefault);

            List<rflib_Logs_Archive__b> records = QUERY_LOCATOR.getRecordsOlderThan(referenceDate);

            List<Database.DeleteResult> result = DML_EXECUTOR.deleteImmediate(records);

            Integer count = 0;
            for (Database.DeleteResult dr : result) {
                if (dr.isSuccess())
                    count++;
            }
            return count;
        } catch (Exception ex) {
            LOGGER.error('Failed to clear rflib_Logs_Archive__b', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    public interface ILogArchiveQueryLocator {
        List<rflib_Logs_Archive__b> getRecords(Datetime startDate, Datetime endDate);
        List<rflib_Logs_Archive__b> getRecordSummaries(Datetime startDate, Datetime endDate);
        List<rflib_Logs_Archive__b> getRecordsOlderThan(Datetime referenceDate);
    }

    public class LogSummaryResult {
        @AuraEnabled
        public final Integer lookbackHours;
        @AuraEnabled
        public final Integer totalCount;
        @AuraEnabled
        public final Boolean truncated;
        @AuraEnabled
        public final List<LogLevelCount> levelCounts;

        public LogSummaryResult(Integer lookbackHours, Map<String, Integer> counts, Boolean truncated) {
            this.lookbackHours = lookbackHours;
            this.truncated = truncated;
            this.levelCounts = new List<LogLevelCount>();

            Integer total = 0;
            Set<String> orderedLevels = new Set<String>{ 'FATAL', 'ERROR', 'WARN' };

            for (String level : orderedLevels) {
                if (counts.containsKey(level) && counts.get(level) > 0) {
                    this.levelCounts.add(new LogLevelCount(level, counts.get(level)));
                    total += counts.get(level);
                }
            }

            for (String level : counts.keySet()) {
                if (!orderedLevels.contains(level) && counts.get(level) > 0) {
                    this.levelCounts.add(new LogLevelCount(level, counts.get(level)));
                    total += counts.get(level);
                }
            }

            this.totalCount = total;
        }
    }

    public class LogLevelCount {
        @AuraEnabled
        public final String level;
        @AuraEnabled
        public final Integer count;

        public LogLevelCount(String level, Integer count) {
            this.level = level;
            this.count = count;
        }
    }

    public class ArchiveQueryResult {
        @AuraEnabled
        public final Integer queryLimit;
        @AuraEnabled
        public final List<rflib_Logs_Archive__b> records;

        public ArchiveQueryResult(Integer queryLimit, List<rflib_Logs_Archive__b> records) {
            this.queryLimit = queryLimit;
            this.records = records;
        }
    }

    public class DefaultLogArchiveQueryLocator implements ILogArchiveQueryLocator {
        public List<rflib_Logs_Archive__b> getRecords(Datetime startDate, Datetime endDate) {
            return (List<rflib_Logs_Archive__b>) rflib_SOQL.of(rflib_Logs_Archive__b.SObjectType)
                .with(
                    new List<SObjectField>{
                        rflib_Logs_Archive__b.CreatedDate__c,
                        rflib_Logs_Archive__b.CreatedById__c,
                        rflib_Logs_Archive__b.Context__c,
                        rflib_Logs_Archive__b.Log_Level__c,
                        rflib_Logs_Archive__b.Request_ID__c,
                        rflib_Logs_Archive__b.Log_Messages__c,
                        rflib_Logs_Archive__b.Platform_Info__c
                    }
                )
                .whereAre(
                    rflib_SOQL.FilterGroup
                        .add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).greaterThan(startDate))
                        .add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).lessThan(endDate))
                )
                .setLimit(ARCHIVE_LOG_QUERY_LIMIT)
                .systemMode()
                .mockId('DefaultLogArchiveQueryLocator.getRecords')
                .toList();
        }

        public List<rflib_Logs_Archive__b> getRecordSummaries(Datetime startDate, Datetime endDate) {
            return (List<rflib_Logs_Archive__b>) rflib_SOQL.of(rflib_Logs_Archive__b.SObjectType)
                .with(
                    new List<SObjectField>{
                        rflib_Logs_Archive__b.CreatedDate__c,
                        rflib_Logs_Archive__b.Log_Level__c,
                        rflib_Logs_Archive__b.Context__c,
                        rflib_Logs_Archive__b.Request_ID__c
                    }
                )
                .whereAre(
                    rflib_SOQL.FilterGroup
                        .add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).greaterThan(startDate))
                        .add(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).lessThan(endDate))
                )
                // Big Objects cannot filter by Log_Level__c (the index prefix is CreatedDate__c), so level
                // filtering happens in Apex. No ORDER BY is applied: the rflib_Log_Index defines CreatedDate__c
                // as ASC, and Big Objects only allow ordering in the index direction, so a DESC sort would fail
                // at runtime. The limit equals the Big Object synchronous query maximum, so any window with up
                // to that many rows is returned in full and counted exactly.
                .setLimit(ARCHIVE_LOG_QUERY_LIMIT)
                .systemMode()
                .mockId('DefaultLogArchiveQueryLocator.getRecordSummaries')
                .toList();
        }

        public List<rflib_Logs_Archive__b> getRecordsOlderThan(Datetime referenceDate) {
            return (List<rflib_Logs_Archive__b>) rflib_SOQL.of(rflib_Logs_Archive__b.SObjectType)
                .with(
                    rflib_Logs_Archive__b.CreatedDate__c,
                    rflib_Logs_Archive__b.Context__c,
                    rflib_Logs_Archive__b.Log_Level__c,
                    rflib_Logs_Archive__b.Request_ID__c
                )
                .orderBy(rflib_Logs_Archive__b.CreatedDate__c)
                .whereAre(rflib_SOQL.Filter.with(rflib_Logs_Archive__b.CreatedDate__c).lessThan(referenceDate))
                .setLimit(ARCHIVE_LOG_QUERY_LIMIT)
                .systemMode()
                .mockId('DefaultLogArchiveQueryLocator.getOldestRecords')
                .toList();
        }
    }
}
