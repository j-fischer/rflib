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
 * @description Default implementation of `rflib_BigObjectQueryService`.
 *
 *              Big Objects have no `OFFSET`, and their index rules - `=` on every filtered field but the last, no
 *              `OR` - rule out tuple-based keyset paging. The cursor is therefore a single value on the first index
 *              field that is not pinned to an exact value, and the next chunk is read with an inclusive comparison
 *              against it. Inclusive, because many records can share that value and an exclusive comparison would
 *              silently skip the ones that did not fit into the previous chunk. The boundary records that were
 *              already returned are then dropped here using their index tuple, which is the primary key of a Big
 *              Object record.
 *
 *              No `ORDER BY` is issued: Big Object queries return their records in index order, which is exactly
 *              the order the cursor relies on. Queries always run in user mode.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_DefaultBigObjectQueryService implements rflib_BigObjectQueryService {
    public static final String QUERY_MOCK_ID = 'rflib_DefaultBigObjectQueryService.queryChunk';

    // The query reads one row beyond the chunk, so a chunk can hold one row less than the synchronous SOQL limit.
    private static final Integer MAX_ROWS_PER_CHUNK = 49999;

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory()
        .createLogger('rflib_DefaultBigObjectQueryService');

    // The generated SOQL and its bind values, kept so tests can assert the predicate without running the query.
    @TestVisible
    private static String lastQuery;

    @TestVisible
    private static Map<String, Object> lastQueryBinding;

    public rflib_BigObjectQueryController.ChunkResult queryChunk(
        rflib_BigObjectQueryController.ResolvedConfig config,
        rflib_BigObjectQueryController.QueryCursor cursor
    ) {
        ChunkQuery chunkQuery = new ChunkQuery(config, cursor);

        rflib_SOQL.FilterGroup filterGroup = chunkQuery.buildFilterGroup();
        if (filterGroup == null) {
            // The cursor has moved past every value of an IN list, so there is nothing left to read.
            return chunkQuery.createResult(new List<SObject>());
        }

        // One row beyond the chunk tells a finished range from one that happens to fill the chunk exactly.
        rflib_SOQL.Queryable query = rflib_SOQL.of(config.objectApiName)
            .with(config.queryFields)
            .setLimit(chunkQuery.chunkSize + 1)
            .mockId(QUERY_MOCK_ID);

        if (filterGroup.hasValues()) {
            query.whereAre(filterGroup);
        }

        lastQuery = query.toString();
        lastQueryBinding = query.binding().clone();
        LOGGER.debug('queryChunk: {0}, binding={1}', new List<Object>{ lastQuery, JSON.serialize(lastQueryBinding) });

        List<SObject> rows = query.userMode().toList();
        return chunkQuery.createResult(rows);
    }

    private static Integer compare(Object left, Object right) {
        if (left instanceof Datetime) {
            Long difference = ((Datetime) left).getTime() - ((Datetime) right).getTime();
            return difference > 0 ? 1 : (difference < 0 ? -1 : 0);
        }
        if (left instanceof Date) {
            return ((Date) right).daysBetween((Date) left);
        }
        if (left instanceof Decimal) {
            Decimal difference = (Decimal) left - (Decimal) right;
            return difference > 0 ? 1 : (difference < 0 ? -1 : 0);
        }
        // compareTo is case-sensitive, unlike the comparison operators on Strings.
        return String.valueOf(left).compareTo(String.valueOf(right));
    }

    /**
     * One chunk request: the configuration, the cursor of the previous chunk, and the index field the cursor sits
     * on, which is the first field not pinned to an exact value.
     */
    private class ChunkQuery {
        private final rflib_BigObjectQueryController.ResolvedConfig config;
        private final rflib_BigObjectQueryController.QueryCursor cursor;
        private final Integer cursorPosition;
        private final String cursorField;
        public final Integer chunkSize;

        public ChunkQuery(
            rflib_BigObjectQueryController.ResolvedConfig config,
            rflib_BigObjectQueryController.QueryCursor cursor
        ) {
            this.config = config;
            this.cursor = cursor;
            this.chunkSize = Math.min(config.chunkSize, MAX_ROWS_PER_CHUNK);
            this.cursorPosition = countExactFilters(config.filters);
            this.cursorField = cursorPosition < config.indexFields.size() ? config.indexFields[cursorPosition] : null;
        }

        public rflib_SOQL.FilterGroup buildFilterGroup() {
            rflib_SOQL.FilterGroup filterGroup = rflib_SOQL.FilterGroup;

            for (Integer i = 0; i < cursorPosition; i++) {
                rflib_BigObjectQueryController.IndexFilter filter = config.filters[i];
                filterGroup.add(rflib_SOQL.Filter.with(filter.fieldName).equal(parse(filter.fieldName, filter.value)));
            }

            if (cursorField == null) {
                return filterGroup;
            }

            Object boundary = cursor?.boundaryValue != null ? parse(cursorField, cursor.boundaryValue) : null;
            Boolean isDescending =
                config.indexDirections[cursorPosition] == rflib_BigObjectQueryController.DIRECTION_DESC;
            rflib_BigObjectQueryController.IndexFilter lastFilter = cursorPosition < config.filters.size()
                ? config.filters[cursorPosition]
                : null;

            if (lastFilter?.operator == rflib_BigObjectQueryController.OPERATOR_IN) {
                List<Object> remainingValues = new List<Object>();
                for (String value : lastFilter.values) {
                    Object typedValue = parse(cursorField, value);
                    Integer comparison = boundary == null ? 0 : compare(typedValue, boundary);
                    if (isDescending ? comparison <= 0 : comparison >= 0) {
                        remainingValues.add(typedValue);
                    }
                }

                if (remainingValues.isEmpty()) {
                    return null;
                }

                // Once the cursor has moved past a value of the list, that value is dropped rather than combining
                // the IN list with a range comparison on the same field.
                filterGroup.add(rflib_SOQL.Filter.with(cursorField).isIn(remainingValues));
                return filterGroup;
            }

            Object fromBound = lastFilter != null ? parse(cursorField, lastFilter.fromValue) : null;
            Object toBound = lastFilter != null ? parse(cursorField, lastFilter.toValue) : null;

            // The cursor tightens the bound the index is read towards, so the field carries at most one comparison
            // in each direction.
            Object lowerBound = !isDescending &&
                boundary != null &&
                (fromBound == null ||
                compare(boundary, fromBound) > 0)
                ? boundary
                : fromBound;
            Object upperBound = isDescending &&
                boundary != null &&
                (toBound == null ||
                compare(boundary, toBound) < 0)
                ? boundary
                : toBound;

            if (lowerBound != null) {
                filterGroup.add(rflib_SOQL.Filter.with(cursorField).greaterOrEqual(lowerBound));
            }
            if (upperBound != null) {
                filterGroup.add(rflib_SOQL.Filter.with(cursorField).lessOrEqual(upperBound));
            }
            return filterGroup;
        }

        public rflib_BigObjectQueryController.ChunkResult createResult(List<SObject> fetchedRows) {
            Boolean hasMoreRows = fetchedRows.size() > chunkSize;
            List<SObject> rows = new List<SObject>();
            for (Integer i = 0; i < Math.min(fetchedRows.size(), chunkSize); i++) {
                rows.add(fetchedRows[i]);
            }

            Set<String> seenKeys = cursor?.seenKeys != null ? new Set<String>(cursor.seenKeys) : new Set<String>();

            List<SObject> newRecords = new List<SObject>();
            for (SObject row : rows) {
                if (!seenKeys.contains(createKey(row))) {
                    newRecords.add(row);
                }
            }

            rflib_BigObjectQueryController.QueryCursor nextCursor = new rflib_BigObjectQueryController.QueryCursor();
            nextCursor.recordsLoaded = (cursor?.recordsLoaded ?? 0) + newRecords.size();
            nextCursor.seenKeys = new List<String>();

            if (cursorField != null && !rows.isEmpty()) {
                // Only the keys at the new boundary are carried forward; the set empties as soon as the value moves on.
                nextCursor.boundaryValue = format(cursorField, rows[rows.size() - 1]);
                for (SObject row : rows) {
                    if (format(cursorField, row) == nextCursor.boundaryValue) {
                        nextCursor.seenKeys.add(createKey(row));
                    }
                }
            }

            rflib_BigObjectQueryController.ChunkResult result = new rflib_BigObjectQueryController.ChunkResult();
            result.records = newRecords;
            result.cursor = nextCursor;
            // With every index field pinned to an exact value, the query addresses a single record and needs no
            // cursor.
            result.isComplete = !hasMoreRows || cursorField == null;

            // A chunk of nothing but records already returned is only stuck when the read-ahead row still carries the
            // boundary value. If it carries the next value, every record at the boundary has been returned, and the
            // index order guarantees nothing lies between the two values, so the cursor moves on to the read-ahead.
            Boolean isBoundaryExhausted = false;
            if (!result.isComplete && newRecords.isEmpty()) {
                String nextValue = format(cursorField, fetchedRows[chunkSize]);
                isBoundaryExhausted = !nextValue.equals(nextCursor.boundaryValue);
                if (isBoundaryExhausted) {
                    nextCursor.boundaryValue = nextValue;
                    nextCursor.seenKeys = new List<String>();
                }
            }
            result.isStuck = !result.isComplete && newRecords.isEmpty() && !isBoundaryExhausted;

            if (result.isStuck) {
                result.message = String.format(
                    'More than {0} records share the value {1} in {2}, so the load cannot continue past them. Raise the chunk size above the number of records with that value.',
                    new List<Object>{ String.valueOf(chunkSize), nextCursor.boundaryValue, cursorField }
                );
            }
            return result;
        }

        private Integer countExactFilters(List<rflib_BigObjectQueryController.IndexFilter> filters) {
            Integer count = 0;
            for (rflib_BigObjectQueryController.IndexFilter filter : filters) {
                if (filter.operator != rflib_BigObjectQueryController.OPERATOR_EQUALS) {
                    break;
                }
                count++;
            }
            return count;
        }

        // JSON-encoded, so text index values that contain any separator cannot make two primary keys collide.
        private String createKey(SObject row) {
            List<String> parts = new List<String>();
            for (String indexField : config.indexFields) {
                parts.add(format(indexField, row));
            }
            return JSON.serialize(parts);
        }

        private String format(String fieldName, SObject row) {
            return rflib_BigObjectQueryController.formatValue(config.getFieldType(fieldName), row.get(fieldName));
        }

        private Object parse(String fieldName, String value) {
            return rflib_BigObjectQueryController.parseValue(config.getFieldType(fieldName), value);
        }
    }
}
