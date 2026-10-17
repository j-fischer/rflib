/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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

/**
 * @group Big Object Explorer
 * @description Controller of the `rflibBigObjectExplorer` LWC. The component is configured entirely through
 *              free-text design attributes, so every request is validated here against the describe of the
 *              configured Big Object before any query is built - the client is never trusted to send a
 *              configuration that `describeConfig()` already accepted.
 *
 *              The component reads any Big Object named in App Builder, so it always queries in `USER_MODE`: the
 *              object and field permissions of the running user decide what it can read, never the placement.
 */
@SuppressWarnings('PMD.ClassNamingConventions,PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
public with sharing class rflib_BigObjectQueryController {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory()
        .createLogger('rflib_BigObjectQueryController');

    public static final String OPERATOR_EQUALS = 'EQUALS';
    public static final String OPERATOR_RANGE = 'RANGE';
    public static final String OPERATOR_IN = 'IN';

    public static final String DIRECTION_ASC = 'ASC';
    public static final String DIRECTION_DESC = 'DESC';

    private static final Integer DEFAULT_CHUNK_SIZE = 2000;
    // The synchronous SOQL row limit; each chunk is its own transaction, so one chunk can never exceed it.
    private static final Integer MAX_CHUNK_SIZE = 50000;
    private static final Integer DEFAULT_FILTERABLE_INDEX_DEPTH = 1;
    private static final String DEFAULT_DATE_FILTER = 'LAST_N_DAYS:7';
    private static final String DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
    private static final String DATE_FORMAT = 'yyyy-MM-dd';
    private static final Pattern LAST_N_DAYS_PATTERN = Pattern.compile('(?i)LAST_N_DAYS:(\\d+)');

    @TestVisible
    private static rflib_BigObjectQueryService QUERY_SERVICE = new rflib_DefaultBigObjectQueryService();

    /**
     * @description Validate the configuration of a placement and resolve the metadata the LWC needs to render it.
     *              Configuration problems are returned rather than thrown, so the component can show them to the
     *              admin in place of the explorer.
     * @param  config The configuration entered in App Builder.
     * @return        The resolved field metadata and default filters, or the list of configuration problems.
     */
    @AuraEnabled
    public static ConfigDescription describeConfig(ExplorerConfig config) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'describeConfig({0})', new List<Object>{ config?.bigObjectApiName });

            ConfigResolver resolver = new ConfigResolver(config);
            ResolvedConfig resolved = resolver.resolve();
            List<IndexFilter> defaultFilters = resolver.hasProblems()
                ? new List<IndexFilter>()
                : resolver.parseDefaultFilter();

            return new ConfigDescription(resolved, defaultFilters, resolver.problems);
        } catch (Exception ex) {
            LOGGER.error('Failed to describe the Big Object Explorer configuration', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Query the next chunk of records for the given configuration and index filters.
     * @param  config The configuration entered in App Builder, including the index filters chosen by the user.
     * @param  cursor The cursor returned with the previous chunk, or `null` to start a new load.
     * @return        The new records of the chunk and the cursor for the next one.
     */
    @AuraEnabled
    public static ChunkResult queryChunk(ExplorerConfig config, QueryCursor cursor) {
        String objectApiName = config?.bigObjectApiName;
        try {
            ConfigResolver resolver = new ConfigResolver(config);
            ResolvedConfig resolved = resolver.resolve();
            if (!resolver.hasProblems()) {
                resolved.filters = resolver.normalizeFilters(config.indexFilters, 'indexFilters');
            }

            if (resolver.hasProblems()) {
                throw new rflib_InvalidArgumentException('config', resolver.describeProblems());
            }

            ChunkResult result = QUERY_SERVICE.queryChunk(resolved, cursor);
            logRead(resolved, result);
            return result;
        } catch (QueryException ex) {
            LOGGER.error('Failed to query ' + objectApiName, ex);
            // Describe does not expose a Big Object's index, so a wrong indexFields attribute only surfaces
            // here, as a query the platform rejects. Name the attribute so the admin knows where to look.
            throw rflib_ControllerUtil.createAuraHandledException(
                String.format(
                    'The query against {0} failed: {1} The most likely cause is an indexFields attribute that does not list the fields of the Big Object index in the order the index declares them.',
                    new List<Object>{ objectApiName, ex.getMessage() }
                )
            );
        } catch (Exception ex) {
            LOGGER.error('Failed to query ' + objectApiName, ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Convert a value from its wire format into the Apex type of the given field type, so it can be
     *              bound into a query. Datetime values travel as ISO-8601 strings in GMT; a plain date is accepted for
     *              a datetime field and means midnight GMT.
     * @param  fieldType The type of the field the value belongs to.
     * @param  value     The value as a string.
     * @return           The typed value, or `null` for a blank value.
     */
    public static Object parseValue(Schema.DisplayType fieldType, String value) {
        if (String.isBlank(value)) {
            return null;
        }

        String trimmed = value.trim();
        try {
            switch on fieldType {
                when DATETIME {
                    String isoValue = trimmed.length() == 10 ? trimmed + 'T00:00:00Z' : trimmed;
                    return (Datetime) JSON.deserialize('"' + isoValue + '"', Datetime.class);
                }
                when DATE {
                    return Date.valueOf(trimmed);
                }
                when DOUBLE, INTEGER, LONG, CURRENCY, PERCENT {
                    return Decimal.valueOf(trimmed);
                }
                when else {
                    return trimmed;
                }
            }
        } catch (Exception ex) {
            throw new rflib_InvalidArgumentException(
                'value',
                String.format('"{0}" is not a valid {1} value', new List<Object>{ trimmed, fieldType })
            );
        }
    }

    /**
     * @description Convert a field value into its wire format. Datetime values are formatted in GMT with millisecond
     *              precision, so a cursor value survives the round trip through JSON and JavaScript unchanged.
     *              The field type is passed in rather than inferred from the value, because a Date also passes
     *              `instanceof Datetime` in Apex.
     * @param  fieldType The type of the field the value belongs to.
     * @param  value     The field value.
     * @return           The value as a string, or `null`.
     */
    public static String formatValue(Schema.DisplayType fieldType, Object value) {
        if (value == null) {
            return null;
        }
        if (fieldType == Schema.DisplayType.DATETIME) {
            return ((Datetime) value).formatGmt(DATETIME_FORMAT);
        }
        if (fieldType == Schema.DisplayType.DATE) {
            return Datetime.newInstanceGmt((Date) value, Time.newInstance(0, 0, 0, 0)).formatGmt(DATE_FORMAT);
        }
        return String.valueOf(value);
    }

    private static void logRead(ResolvedConfig resolved, ChunkResult result) {
        LOGGER.info(
            'Big Object Explorer read {0} records from {1} ({2} loaded so far), fields: {3}',
            new List<Object>{
                result.records.size(),
                resolved.objectApiName,
                result.cursor.recordsLoaded,
                String.join(resolved.queryFields, ',')
            }
        );
    }

    // Relative windows mirror SOQL's date literals and resolve in GMT, the same way the cursor values are formatted.
    private static List<Date> resolveRelativeDate(String value) {
        Date today = Datetime.now().dateGmt();
        String normalized = value.trim().toUpperCase();

        if (normalized == 'TODAY') {
            return new List<Date>{ today, today };
        }
        if (normalized == 'YESTERDAY') {
            return new List<Date>{ today.addDays(-1), today.addDays(-1) };
        }
        if (normalized == 'THIS_MONTH') {
            Date firstOfMonth = today.toStartOfMonth();
            return new List<Date>{ firstOfMonth, firstOfMonth.addMonths(1).addDays(-1) };
        }

        Matcher lastNDays = LAST_N_DAYS_PATTERN.matcher(normalized);
        if (lastNDays.matches()) {
            return new List<Date>{ today.addDays(-1 * Integer.valueOf(lastNDays.group(1))), today };
        }
        return null;
    }

    private static String formatDateBound(Date day, Schema.DisplayType fieldType, Boolean isEndOfDay) {
        if (fieldType == Schema.DisplayType.DATE) {
            return formatValue(Schema.DisplayType.DATE, day);
        }
        Time timeOfDay = isEndOfDay ? Time.newInstance(23, 59, 59, 999) : Time.newInstance(0, 0, 0, 0);
        return formatValue(Schema.DisplayType.DATETIME, Datetime.newInstanceGmt(day, timeOfDay));
    }

    // Field lists keep the order they were configured in, which a Set does not guarantee: the order of the index
    // fields decides filter validation, sort directions and where the cursor sits.
    private static List<String> appendDistinct(List<String> target, List<String> values) {
        for (String value : values) {
            if (!target.contains(value)) {
                target.add(value);
            }
        }
        return target;
    }

    private static Boolean hasValues(List<String> values) {
        if (values == null) {
            return false;
        }
        for (String value : values) {
            if (String.isNotBlank(value)) {
                return true;
            }
        }
        return false;
    }

    private static String toDataType(Schema.DescribeFieldResult fieldDescribe) {
        switch on fieldDescribe.getType() {
            when DATETIME {
                return 'datetime';
            }
            when DATE {
                return 'date';
            }
            when DOUBLE, INTEGER, LONG, CURRENCY, PERCENT {
                return 'number';
            }
            when TEXTAREA {
                return fieldDescribe.getLength() > 255 ? 'longtext' : 'text';
            }
            when else {
                return 'text';
            }
        }
    }

    /**
     * Validates one configuration against the describe of its Big Object and collects every problem it finds, so
     * an admin sees all of them at once rather than one per save.
     */
    private class ConfigResolver {
        private final ExplorerConfig config;
        private final ResolvedConfig resolved = new ResolvedConfig();
        public final List<ConfigProblem> problems = new List<ConfigProblem>();
        private Map<String, Schema.SObjectField> fieldMap;

        public ConfigResolver(ExplorerConfig config) {
            this.config = config;
        }

        public Boolean hasProblems() {
            return !problems.isEmpty();
        }

        public String describeProblems() {
            List<String> messages = new List<String>();
            for (ConfigProblem problem : problems) {
                messages.add(problem.attribute + ': ' + problem.message);
            }
            return String.join(messages, ' ');
        }

        public ResolvedConfig resolve() {
            String objectApiName = config?.bigObjectApiName?.trim();
            if (String.isBlank(objectApiName)) {
                addProblem('bigObjectApiName', 'A Big Object API name is required.', new List<Object>());
                return null;
            }

            // The component is a Big Object reader, not a general-purpose SOQL runner.
            if (!objectApiName.endsWithIgnoreCase('__b')) {
                addProblem(
                    'bigObjectApiName',
                    '{0} is not a Big Object. The API name must end in __b.',
                    new List<Object>{ objectApiName }
                );
                return null;
            }

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            if (objectType == null) {
                addProblem('bigObjectApiName', 'The Big Object {0} does not exist.', new List<Object>{ objectApiName });
                return null;
            }

            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            resolved.objectApiName = objectDescribe.getName();
            resolved.objectLabel = objectDescribe.getLabel();
            if (!objectDescribe.isAccessible()) {
                addProblem(
                    'bigObjectApiName',
                    'You do not have read access to {0}.',
                    new List<Object>{ resolved.objectApiName }
                );
                return null;
            }

            fieldMap = objectDescribe.fields.getMap();

            resolved.indexFields = resolveFields('indexFields', config.indexFields);
            if (resolved.indexFields.isEmpty()) {
                addProblem('indexFields', 'At least one index field is required.', new List<Object>());
            }

            resolved.displayFields = resolveFields('displayFields', config.displayFields);
            if (resolved.displayFields.isEmpty()) {
                addProblem('displayFields', 'At least one display field is required.', new List<Object>());
            }

            resolved.detailFields = hasValues(config.detailFields)
                ? resolveFields('detailFields', config.detailFields)
                : getAllCustomFields();

            resolved.indexDirections = resolveDirections();
            resolved.chunkSize = resolveChunkSize();
            resolved.filterableIndexDepth = resolveFilterableIndexDepth();

            enforceFieldAccess();

            // The query field set is derived rather than configured, so there is no fourth list to keep in sync.
            resolved.queryFields = appendDistinct(new List<String>(), resolved.indexFields);
            appendDistinct(resolved.queryFields, resolved.displayFields);
            appendDistinct(resolved.queryFields, resolved.detailFields);

            return resolved;
        }

        public List<IndexFilter> parseDefaultFilter() {
            // An archive is usually browsed by recency, so a date-led index starts on the last seven days. Any other
            // index has no sensible default and starts unfiltered.
            Schema.DisplayType leadingType = resolved.getFieldType(resolved.indexFields[0]);
            Boolean isDateLed = leadingType == Schema.DisplayType.DATETIME || leadingType == Schema.DisplayType.DATE;
            String grammar = String.isNotBlank(config.defaultFilter)
                ? config.defaultFilter
                : (isDateLed ? resolved.indexFields[0] + '=' + DEFAULT_DATE_FILTER : '');

            List<IndexFilter> filters = new List<IndexFilter>();
            for (String term : grammar.split(';')) {
                if (String.isBlank(term)) {
                    continue;
                }

                Integer separatorIndex = term.indexOf('=');
                if (separatorIndex < 1) {
                    addProblem(
                        'defaultFilter',
                        'The term "{0}" is not in the form Field=value.',
                        new List<Object>{ term.trim() }
                    );
                    continue;
                }

                filters.add(
                    parseTerm(term.substring(0, separatorIndex).trim(), term.substring(separatorIndex + 1).trim())
                );
            }

            return normalizeFilters(filters, 'defaultFilter');
        }

        /**
         * Index filters must form a legal Big Object predicate: exact values on a left-to-right prefix of the
         * index, followed by at most one range or IN list, within the filterable depth. The LWC only lets a user
         * build that shape, but the request is validated again here because the client is not trusted.
         */
        public List<IndexFilter> normalizeFilters(List<IndexFilter> filters, String attribute) {
            List<IndexFilter> result = new List<IndexFilter>();
            if (filters == null) {
                return result;
            }

            for (Integer i = 0; i < filters.size(); i++) {
                IndexFilter filter = filters[i];
                String fieldName = resolved.canonicalIndexField(filter.fieldName);

                if (fieldName == null || resolved.indexFields.indexOf(fieldName) != i) {
                    String expected = i < resolved.indexFields.size() ? resolved.indexFields[i] : null;
                    addProblem(
                        attribute,
                        'The filter on {0} does not follow the index order. Filter number {1} must be on {2}.',
                        new List<Object>{
                            filter.fieldName,
                            String.valueOf(i + 1),
                            expected ?? 'no field, as the index has no more fields'
                        }
                    );
                    continue;
                }

                if (i >= resolved.filterableIndexDepth) {
                    addProblem(
                        attribute,
                        'The filter on {0} is beyond the filterable index depth of {1}.',
                        new List<Object>{ fieldName, String.valueOf(resolved.filterableIndexDepth) }
                    );
                    continue;
                }

                if (filter.operator != OPERATOR_EQUALS && i < filters.size() - 1) {
                    addProblem(
                        attribute,
                        'The filter on {0} must be an exact value, because only the last filter may be a range or a list of values.',
                        new List<Object>{ fieldName }
                    );
                    continue;
                }

                filter.fieldName = fieldName;
                if (hasValidValues(filter, attribute)) {
                    result.add(filter);
                }
            }
            return result;
        }

        private void addProblem(String attribute, String message, List<Object> args) {
            problems.add(new ConfigProblem(attribute, String.format(message, args)));
        }

        private List<String> resolveFields(String attribute, List<String> fieldNames) {
            List<String> result = new List<String>();
            if (fieldNames == null) {
                return result;
            }

            for (String fieldName : fieldNames) {
                if (String.isBlank(fieldName)) {
                    continue;
                }

                Schema.SObjectField field = fieldMap.get(fieldName.trim().toLowerCase());
                if (field == null) {
                    addProblem(
                        attribute,
                        'The field {0} does not exist on {1}.',
                        new List<Object>{ fieldName.trim(), resolved.objectApiName }
                    );
                    continue;
                }

                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                resolved.fieldDescribes.put(fieldDescribe.getName(), fieldDescribe);
                appendDistinct(result, new List<String>{ fieldDescribe.getName() });
            }

            return result;
        }

        private List<String> getAllCustomFields() {
            // Index fields lead in index order; the remaining custom fields follow alphabetically, since the
            // describe map has no meaningful order.
            List<String> otherFields = new List<String>();

            for (Schema.SObjectField field : fieldMap.values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if (fieldDescribe.isCustom() && !resolved.indexFields.contains(fieldDescribe.getName())) {
                    resolved.fieldDescribes.put(fieldDescribe.getName(), fieldDescribe);
                    otherFields.add(fieldDescribe.getName());
                }
            }

            otherFields.sort();
            return appendDistinct(new List<String>(resolved.indexFields), otherFields);
        }

        private void enforceFieldAccess() {
            for (String fieldName : resolved.indexFields) {
                if (!resolved.fieldDescribes.get(fieldName).isAccessible()) {
                    addProblem(
                        'indexFields',
                        'You do not have read access to the field {0}.',
                        new List<Object>{ fieldName }
                    );
                }
            }

            // A field the user cannot read is dropped rather than failing the load, so a user without access to,
            // say, a long payload field can still search the rest of the archive.
            resolved.displayFields = removeInaccessibleFields(resolved.displayFields);
            resolved.detailFields = removeInaccessibleFields(resolved.detailFields);
        }

        private List<String> removeInaccessibleFields(List<String> fieldNames) {
            List<String> result = new List<String>();
            for (String fieldName : fieldNames) {
                if (resolved.fieldDescribes.get(fieldName).isAccessible()) {
                    result.add(fieldName);
                } else if (!resolved.droppedFields.contains(fieldName)) {
                    resolved.droppedFields.add(fieldName);
                }
            }
            return result;
        }

        private List<String> resolveDirections() {
            Integer numIndexFields = resolved.indexFields.size();
            List<String> result = new List<String>();
            if (String.isNotBlank(config.sortDirection)) {
                for (String direction : config.sortDirection.split(',')) {
                    String normalized = direction.trim().toUpperCase();
                    if (normalized != DIRECTION_ASC && normalized != DIRECTION_DESC) {
                        addProblem(
                            'indexSortDirection',
                            '"{0}" is not a sort direction. Use ASC or DESC.',
                            new List<Object>{ direction.trim() }
                        );
                    }
                    result.add(normalized);
                }
            }

            if (result.size() > numIndexFields && numIndexFields > 0) {
                addProblem(
                    'indexSortDirection',
                    'There are more sort directions than index fields. List one direction per index field.',
                    new List<Object>()
                );
            }

            if (result.isEmpty()) {
                result.add(DIRECTION_DESC);
            }

            // The leading direction is the one that matters for the archive use case; any index field after it
            // whose direction was not listed falls back to ASC.
            while (result.size() < numIndexFields) {
                result.add(DIRECTION_ASC);
            }
            return result;
        }

        private Integer resolveChunkSize() {
            Integer chunkSize = config.chunkSize ?? DEFAULT_CHUNK_SIZE;
            if (chunkSize < 1 || chunkSize > MAX_CHUNK_SIZE) {
                addProblem(
                    'chunkSize',
                    'The chunk size must be between 1 and {0}.',
                    new List<Object>{ String.valueOf(MAX_CHUNK_SIZE) }
                );
            }
            return chunkSize;
        }

        private Integer resolveFilterableIndexDepth() {
            Integer numIndexFields = resolved.indexFields.size();
            Integer depth = config.filterableIndexDepth ?? DEFAULT_FILTERABLE_INDEX_DEPTH;
            if (depth < 1 || (numIndexFields > 0 && depth > numIndexFields)) {
                addProblem(
                    'filterableIndexDepth',
                    'The filterable index depth must be between 1 and the number of index fields ({0}).',
                    new List<Object>{ String.valueOf(numIndexFields) }
                );
            }
            return depth;
        }

        private IndexFilter parseTerm(String fieldName, String value) {
            IndexFilter filter = new IndexFilter();
            filter.fieldName = fieldName;

            Schema.DisplayType fieldType = resolved.getFieldType(resolved.canonicalIndexField(fieldName));
            if (fieldType == Schema.DisplayType.DATETIME || fieldType == Schema.DisplayType.DATE) {
                List<Date> window = resolveRelativeDate(value);
                if (window != null) {
                    filter.operator = OPERATOR_RANGE;
                    filter.fromValue = formatDateBound(window[0], fieldType, false);
                    filter.toValue = formatDateBound(window[1], fieldType, true);
                    return filter;
                }
            }

            if (value.contains('..')) {
                List<String> bounds = value.split('\\.\\.', -1);
                filter.operator = OPERATOR_RANGE;
                filter.fromValue = String.isBlank(bounds[0]) ? null : bounds[0].trim();
                filter.toValue = bounds.size() < 2 || String.isBlank(bounds[1]) ? null : bounds[1].trim();
            } else if (value.contains(',')) {
                filter.operator = OPERATOR_IN;
                filter.values = new List<String>();
                for (String item : value.split(',')) {
                    if (String.isNotBlank(item)) {
                        filter.values.add(item.trim());
                    }
                }
            } else {
                filter.operator = OPERATOR_EQUALS;
                filter.value = value;
            }
            return filter;
        }

        private Boolean hasValidValues(IndexFilter filter, String attribute) {
            List<String> rawValues = new List<String>();
            if (filter.operator == OPERATOR_EQUALS && String.isNotBlank(filter.value)) {
                rawValues.add(filter.value);
            } else if (
                filter.operator == OPERATOR_RANGE &&
                (String.isNotBlank(filter.fromValue) || String.isNotBlank(filter.toValue))
            ) {
                rawValues.add(filter.fromValue);
                rawValues.add(filter.toValue);
            } else if (filter.operator == OPERATOR_IN && filter.values != null && !filter.values.isEmpty()) {
                rawValues.addAll(filter.values);
            } else {
                addProblem(
                    attribute,
                    'The filter on {0} has no value, or its operator {1} is not one of EQUALS, RANGE or IN.',
                    new List<Object>{ filter.fieldName, filter.operator }
                );
                return false;
            }

            try {
                Schema.DisplayType fieldType = resolved.getFieldType(filter.fieldName);
                for (String rawValue : rawValues) {
                    parseValue(fieldType, rawValue);
                }
            } catch (rflib_InvalidArgumentException ex) {
                addProblem(
                    attribute,
                    'The filter on {0} has an invalid value: {1}',
                    new List<Object>{ filter.fieldName, ex.getMessage() }
                );
                return false;
            }
            return true;
        }
    }

    /**
     * @description The configuration of a placement, as entered in App Builder, plus the index filters the user
     *              chose at runtime. Lists arrive already split by the LWC.
     */
    public class ExplorerConfig {
        @AuraEnabled
        public String bigObjectApiName { get; set; }
        @AuraEnabled
        public List<String> indexFields { get; set; }
        @AuraEnabled
        public String sortDirection { get; set; }
        @AuraEnabled
        public List<String> displayFields { get; set; }
        @AuraEnabled
        public List<String> detailFields { get; set; }
        @AuraEnabled
        public String defaultFilter { get; set; }
        @AuraEnabled
        public Integer filterableIndexDepth { get; set; }
        @AuraEnabled
        public Integer chunkSize { get; set; }
        @AuraEnabled
        public List<IndexFilter> indexFilters { get; set; }
    }

    /**
     * @description One condition on an index field. `EQUALS` uses `value`, `RANGE` uses the inclusive `fromValue`
     *              and `toValue` (either may be blank for an open bound), and `IN` uses `values`.
     */
    public class IndexFilter {
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public String operator { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public List<String> values { get; set; }
        @AuraEnabled
        public String fromValue { get; set; }
        @AuraEnabled
        public String toValue { get; set; }
    }

    /**
     * @description Position of a load. The cursor sits on the first index field that is not pinned to an exact
     *              value; `seenKeys` holds the index tuples already returned at `boundaryValue` only, so it stays
     *              small no matter how many records the load has returned.
     */
    public class QueryCursor {
        @AuraEnabled
        public String boundaryValue { get; set; }
        @AuraEnabled
        public List<String> seenKeys { get; set; }
        @AuraEnabled
        public Integer recordsLoaded { get; set; }
    }

    /**
     * @description One chunk of records. `isStuck` means the cursor cannot advance because more records share
     *              one index value than fit into a chunk; `message` then explains how to fix the configuration.
     */
    public class ChunkResult {
        @AuraEnabled
        public List<SObject> records;
        @AuraEnabled
        public QueryCursor cursor;
        @AuraEnabled
        public Boolean isComplete;
        @AuraEnabled
        public Boolean isStuck;
        @AuraEnabled
        public String message;
    }

    /**
     * @description Metadata of one queried field. `dataType` is one of `datetime`, `date`, `number`, `text` or
     *              `longtext`, which is all the LWC needs to choose a filter input and a renderer.
     */
    public class FieldInfo {
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String dataType;

        public FieldInfo(Schema.DescribeFieldResult fieldDescribe) {
            this.apiName = fieldDescribe.getName();
            this.label = fieldDescribe.getLabel();
            this.dataType = toDataType(fieldDescribe);
        }
    }

    /**
     * @description A configuration problem, naming the design attribute that causes it.
     */
    public class ConfigProblem {
        @AuraEnabled
        public String attribute;
        @AuraEnabled
        public String message;

        public ConfigProblem(String attribute, String message) {
            this.attribute = attribute;
            this.message = message;
        }
    }

    /**
     * @description The result of `describeConfig()`: either the resolved configuration, or the problems that
     *              prevent it from being used.
     */
    public class ConfigDescription {
        @AuraEnabled
        public Boolean isValid;
        @AuraEnabled
        public List<ConfigProblem> problems;
        @AuraEnabled
        public String objectApiName;
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public List<FieldInfo> fields;
        @AuraEnabled
        public List<String> indexFields;
        @AuraEnabled
        public List<String> displayFields;
        @AuraEnabled
        public List<String> detailFields;
        @AuraEnabled
        public List<String> droppedFields;
        @AuraEnabled
        public List<IndexFilter> defaultFilters;
        @AuraEnabled
        public Integer filterableIndexDepth;

        public ConfigDescription(
            ResolvedConfig resolved,
            List<IndexFilter> defaultFilters,
            List<ConfigProblem> problems
        ) {
            this.problems = problems;
            this.isValid = problems.isEmpty();
            if (!this.isValid) {
                return;
            }

            this.objectApiName = resolved.objectApiName;
            this.objectLabel = resolved.objectLabel;
            this.indexFields = resolved.indexFields;
            this.displayFields = resolved.displayFields;
            this.detailFields = resolved.detailFields;
            this.droppedFields = resolved.droppedFields;
            this.defaultFilters = defaultFilters;
            this.filterableIndexDepth = resolved.filterableIndexDepth;

            this.fields = new List<FieldInfo>();
            for (String fieldName : resolved.queryFields) {
                this.fields.add(new FieldInfo(resolved.fieldDescribes.get(fieldName)));
            }
        }
    }

    /**
     * @description The validated configuration handed to the query service. Field names are in their canonical
     *              case, so they match the keys of the queried records.
     */
    public class ResolvedConfig {
        public String objectApiName;
        public String objectLabel;
        public List<String> indexFields = new List<String>();
        public List<String> indexDirections = new List<String>();
        public List<String> displayFields = new List<String>();
        public List<String> detailFields = new List<String>();
        public List<String> queryFields = new List<String>();
        public List<String> droppedFields = new List<String>();
        public List<IndexFilter> filters = new List<IndexFilter>();
        public Integer chunkSize;
        public Integer filterableIndexDepth;
        public Map<String, Schema.DescribeFieldResult> fieldDescribes = new Map<String, Schema.DescribeFieldResult>();

        public Schema.DisplayType getFieldType(String fieldName) {
            return fieldName != null && fieldDescribes.containsKey(fieldName)
                ? fieldDescribes.get(fieldName).getType()
                : Schema.DisplayType.STRING;
        }

        public String canonicalIndexField(String fieldName) {
            if (String.isBlank(fieldName)) {
                return null;
            }
            for (String indexField : indexFields) {
                if (indexField.equalsIgnoreCase(fieldName.trim())) {
                    return indexField;
                }
            }
            return null;
        }
    }
}
