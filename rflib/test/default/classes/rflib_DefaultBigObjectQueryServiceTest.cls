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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_DefaultBigObjectQueryServiceTest {
    private static final String MOCK_ID = rflib_DefaultBigObjectQueryService.QUERY_MOCK_ID;

    private static final Datetime BOUNDARY = Datetime.newInstanceGmt(2026, 10, 1, 12, 0, 0);
    private static final Datetime EARLIER = BOUNDARY.addMinutes(-5);
    private static final Datetime EARLIEST = BOUNDARY.addMinutes(-10);

    private static final List<String> INDEX_FIELDS = new List<String>{
        'Occurred_On__c',
        'Event_Name__c',
        'Related_Record_ID__c',
        'Created_By_ID__c'
    };

    @IsTest
    private static void testQueryChunk_FirstChunkHasNoCursorPredicate() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 3);
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ createRecord(BOUNDARY, 'A'), createRecord(EARLIER, 'B') });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, null);

        Assert.areEqual(2, result.records.size());
        Assert.isTrue(result.isComplete, 'A chunk shorter than the chunk size completes the load');
        Assert.isFalse(result.isStuck);
        Assert.areEqual(2, result.cursor.recordsLoaded);
        Assert.areEqual(iso(EARLIER), result.cursor.boundaryValue);
        Assert.areEqual(1, result.cursor.seenKeys.size());

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isFalse(soql.contains('WHERE'), 'The first unfiltered chunk has no predicate: ' + soql);
        Assert.isFalse(soql.contains('ORDER BY'), 'Big Objects return index order without ORDER BY: ' + soql);
        Assert.isTrue(soql.contains('LIMIT 4'), 'One row beyond the chunk is read ahead: ' + soql);
        Assert.isTrue(soql.contains('Additional_Details__c'), soql);
    }

    @IsTest
    private static void testQueryChunk_ReadAheadStaysWithinTheSoqlRowLimit() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 50000);
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        new rflib_DefaultBigObjectQueryService().queryChunk(config, null);

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('LIMIT 50000'), 'The largest chunk reads 49,999 rows plus one ahead: ' + soql);
    }

    @IsTest
    private static void testQueryChunk_DescendingCursorUsesInclusiveUpperBound() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 3);
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        new rflib_DefaultBigObjectQueryService().queryChunk(config, createCursor(BOUNDARY, new List<String>(), 3));

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('Occurred_On__c <= :v1'), soql);
        Assert.isFalse(soql.contains('>='), soql);
        Assert.areEqual(BOUNDARY, rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v1'));
    }

    @IsTest
    private static void testQueryChunk_AscendingCursorUsesInclusiveLowerBound() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('ASC', 3);
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        new rflib_DefaultBigObjectQueryService().queryChunk(config, createCursor(BOUNDARY, new List<String>(), 3));

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('Occurred_On__c >= :v1'), soql);
        Assert.isFalse(soql.contains('<='), soql);
    }

    @IsTest
    private static void testQueryChunk_DropsBoundaryRecordsAlreadySeenAndResetsSeenKeys() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 4);
        rflib_Application_Event_Archive__b seenA = createRecord(BOUNDARY, 'A');
        rflib_Application_Event_Archive__b seenB = createRecord(BOUNDARY, 'B');
        rflib_Application_Event_Archive__b newC = createRecord(BOUNDARY, 'C');
        rflib_Application_Event_Archive__b newD = createRecord(EARLIER, 'D');
        rflib_Application_Event_Archive__b readAheadE = createRecord(EARLIEST, 'E');
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ seenA, seenB, newC, newD, readAheadE });

        rflib_BigObjectQueryController.QueryCursor cursor = createCursor(
            BOUNDARY,
            new List<String>{ createKey(seenA), createKey(seenB) },
            10
        );

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, cursor);

        Assert.areEqual(2, result.records.size());
        Assert.areEqual('C', result.records[0].get('Event_Name__c'));
        Assert.areEqual('D', result.records[1].get('Event_Name__c'));
        Assert.areEqual(12, result.cursor.recordsLoaded);
        Assert.isFalse(result.isComplete, 'The read-ahead row shows that more records follow');

        Assert.areEqual(iso(EARLIER), result.cursor.boundaryValue);
        Assert.areEqual(
            new List<String>{ createKey(newD) },
            result.cursor.seenKeys,
            'Only the keys at the new boundary are carried forward'
        );
    }

    @IsTest
    private static void testQueryChunk_SeenKeysGrowWhileTheBoundaryStays() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 3);
        rflib_Application_Event_Archive__b seenA = createRecord(BOUNDARY, 'A');
        rflib_Application_Event_Archive__b seenB = createRecord(BOUNDARY, 'B');
        rflib_Application_Event_Archive__b newC = createRecord(BOUNDARY, 'C');
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ seenA, seenB, newC });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, createCursor(BOUNDARY, new List<String>{ createKey(seenA), createKey(seenB) }, 2));

        Assert.areEqual(1, result.records.size());
        Assert.isFalse(result.isStuck, 'One new record is progress');
        Assert.areEqual(iso(BOUNDARY), result.cursor.boundaryValue);
        Assert.areEqual(
            new List<String>{ createKey(seenA), createKey(seenB), createKey(newC) },
            result.cursor.seenKeys
        );
    }

    @IsTest
    private static void testQueryChunk_FullChunkWithoutNewRecordsIsStuck() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 2);
        rflib_Application_Event_Archive__b seenA = createRecord(BOUNDARY, 'A');
        rflib_Application_Event_Archive__b seenB = createRecord(BOUNDARY, 'B');
        rflib_Application_Event_Archive__b readAheadC = createRecord(BOUNDARY, 'C');
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ seenA, seenB, readAheadC });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, createCursor(BOUNDARY, new List<String>{ createKey(seenA), createKey(seenB) }, 2));

        Assert.isTrue(result.isStuck);
        Assert.isFalse(result.isComplete);
        Assert.isTrue(result.records.isEmpty());
        Assert.isTrue(result.message.contains('Occurred_On__c'), result.message);
        Assert.isTrue(result.message.contains(iso(BOUNDARY)), result.message);
        Assert.isTrue(result.message.contains('More than 2 records'), result.message);
    }

    @IsTest
    private static void testQueryChunk_ExactlyFullBoundaryThatEndsTheRangeIsComplete() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 2);
        rflib_Application_Event_Archive__b seenA = createRecord(BOUNDARY, 'A');
        rflib_Application_Event_Archive__b seenB = createRecord(BOUNDARY, 'B');
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ seenA, seenB });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, createCursor(BOUNDARY, new List<String>{ createKey(seenA), createKey(seenB) }, 2));

        Assert.isTrue(result.isComplete, 'No read-ahead row means the boundary was the end of the range');
        Assert.isFalse(result.isStuck);
        Assert.isTrue(result.records.isEmpty());
    }

    @IsTest
    private static void testQueryChunk_ExactlyFullBoundaryFollowedByMoreRecordsAdvances() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 2);
        rflib_Application_Event_Archive__b seenA = createRecord(BOUNDARY, 'A');
        rflib_Application_Event_Archive__b seenB = createRecord(BOUNDARY, 'B');
        rflib_Application_Event_Archive__b readAheadC = createRecord(EARLIER, 'C');
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ seenA, seenB, readAheadC });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, createCursor(BOUNDARY, new List<String>{ createKey(seenA), createKey(seenB) }, 2));

        Assert.isFalse(result.isStuck, 'Exactly chunk-size records at the boundary are not a stuck load');
        Assert.isFalse(result.isComplete);
        Assert.isTrue(result.records.isEmpty());
        Assert.areEqual(iso(EARLIER), result.cursor.boundaryValue, 'The cursor moves on to the read-ahead value');
        Assert.isTrue(result.cursor.seenKeys.isEmpty());
        Assert.areEqual(2, result.cursor.recordsLoaded);
    }

    @IsTest
    private static void testQueryChunk_KeysDoNotCollideOnSeparatorsInValues() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 3);
        rflib_Application_Event_Archive__b seen = createRecord(BOUNDARY, 'x||y');
        seen.Related_Record_ID__c = 'z';
        rflib_Application_Event_Archive__b other = createRecord(BOUNDARY, 'x');
        other.Related_Record_ID__c = 'y||z';
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ seen, other });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, createCursor(BOUNDARY, new List<String>{ createKey(seen) }, 1));

        Assert.areEqual(1, result.records.size(), 'Only the record already seen is dropped');
        Assert.areEqual('x', result.records[0].get('Event_Name__c'));
    }

    @IsTest
    private static void testQueryChunk_CursorTightensTheUpperBoundOfARange() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 3);
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createRange('Occurred_On__c', EARLIEST, BOUNDARY.addDays(1))
        };
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        new rflib_DefaultBigObjectQueryService().queryChunk(config, createCursor(BOUNDARY, new List<String>(), 3));

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('Occurred_On__c >= :v1 AND Occurred_On__c <= :v2'), soql);
        Assert.areEqual(EARLIEST, rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v1'));
        Assert.areEqual(BOUNDARY, rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v2'));
    }

    @IsTest
    private static void testQueryChunk_RangeBoundWinsWhenTighterThanTheCursor() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('ASC', 3);
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createRange('Occurred_On__c', BOUNDARY, null)
        };
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        new rflib_DefaultBigObjectQueryService().queryChunk(config, createCursor(EARLIER, new List<String>(), 3));

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('Occurred_On__c >= :v1'), soql);
        Assert.isFalse(soql.contains('<='), soql);
        Assert.areEqual(BOUNDARY, rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v1'));
    }

    @IsTest
    private static void testQueryChunk_ExactFiltersMoveTheCursorToTheNextIndexField() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 2);
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createEquals('Occurred_On__c', iso(BOUNDARY))
        };
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ createRecord(BOUNDARY, 'B'), createRecord(BOUNDARY, 'C') });

        rflib_BigObjectQueryController.QueryCursor cursor = new rflib_BigObjectQueryController.QueryCursor();
        cursor.boundaryValue = 'B';

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, cursor);

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('Occurred_On__c = :v1 AND Event_Name__c >= :v2'), soql);
        Assert.areEqual('B', rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v2'));
        Assert.areEqual('C', result.cursor.boundaryValue, 'The cursor sits on Event_Name__c');
    }

    @IsTest
    private static void testQueryChunk_InListDropsValuesTheCursorHasPassed() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 2);
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createEquals('Occurred_On__c', iso(BOUNDARY)),
            createIn('Event_Name__c', new List<String>{ 'A', 'B', 'C' })
        };
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        rflib_BigObjectQueryController.QueryCursor cursor = new rflib_BigObjectQueryController.QueryCursor();
        cursor.boundaryValue = 'B';

        new rflib_DefaultBigObjectQueryService().queryChunk(config, cursor);

        String soql = rflib_DefaultBigObjectQueryService.lastQuery;
        Assert.isTrue(soql.contains('Event_Name__c IN :v2'), soql);
        Assert.areEqual(
            new List<Object>{ 'B', 'C' },
            rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v2'),
            'A is before the cursor of an ascending field and has been read completely'
        );
    }

    @IsTest
    private static void testQueryChunk_InListExhaustedCompletesWithoutQuerying() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 2);
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createEquals('Occurred_On__c', iso(BOUNDARY)),
            createIn('Event_Name__c', new List<String>{ 'A', 'B' })
        };

        rflib_BigObjectQueryController.QueryCursor cursor = new rflib_BigObjectQueryController.QueryCursor();
        cursor.boundaryValue = 'C';
        cursor.recordsLoaded = 5;

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, cursor);

        Assert.isNull(rflib_DefaultBigObjectQueryService.lastQuery, 'No query is issued');
        Assert.isTrue(result.isComplete);
        Assert.isTrue(result.records.isEmpty());
        Assert.areEqual(5, result.cursor.recordsLoaded);
    }

    @IsTest
    private static void testQueryChunk_FullyPinnedIndexNeedsNoCursor() {
        rflib_BigObjectQueryController.ResolvedConfig config = createConfig('DESC', 1);
        config.useSystemMode = true;
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createEquals('Occurred_On__c', iso(BOUNDARY)),
            createEquals('Event_Name__c', 'A'),
            createEquals('Related_Record_ID__c', 'REL'),
            createEquals('Created_By_ID__c', 'USER')
        };
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ createRecord(BOUNDARY, 'A') });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, null);

        Assert.isTrue(result.isComplete, 'A single addressed record completes the load even when it fills the chunk');
        Assert.isNull(result.cursor.boundaryValue);
        Assert.areEqual(1, result.records.size());
    }

    @IsTest
    private static void testQueryChunk_FormatsADateCursorAsADate() {
        rflib_BigObjectQueryController.ResolvedConfig config = new rflib_BigObjectQueryController.ResolvedConfig();
        config.objectApiName = 'Opportunity';
        config.indexFields = new List<String>{ 'CloseDate' };
        config.indexDirections = new List<String>{ 'ASC' };
        config.queryFields = config.indexFields;
        config.chunkSize = 1;
        config.fieldDescribes.put('CloseDate', Opportunity.CloseDate.getDescribe());
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>{ new Opportunity(CloseDate = Date.newInstance(2026, 10, 1)) });

        rflib_BigObjectQueryController.ChunkResult result = new rflib_DefaultBigObjectQueryService()
            .queryChunk(config, null);

        Assert.areEqual('2026-10-01', result.cursor.boundaryValue, 'A Date also passes instanceof Datetime in Apex');
        Assert.areEqual(new List<String>{ JSON.serialize(new List<String>{ '2026-10-01' }) }, result.cursor.seenKeys);
    }

    @IsTest
    private static void testQueryChunk_ComparesNumbersAndDates() {
        // Big Object index fields can also be numbers or dates. The query is mocked, so the cursor arithmetic can
        // be exercised against the describe of standard fields of those types.
        rflib_BigObjectQueryController.ResolvedConfig config = new rflib_BigObjectQueryController.ResolvedConfig();
        config.objectApiName = 'Opportunity';
        config.indexFields = new List<String>{ 'CloseDate', 'Amount' };
        config.indexDirections = new List<String>{ 'ASC', 'DESC' };
        config.queryFields = config.indexFields;
        config.chunkSize = 10;
        config.fieldDescribes.put('CloseDate', Opportunity.CloseDate.getDescribe());
        config.fieldDescribes.put('Amount', Opportunity.Amount.getDescribe());
        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createEquals('CloseDate', '2026-10-01'),
            createIn('Amount', new List<String>{ '100', '200', '300' })
        };
        rflib_SOQL.setMock(MOCK_ID, new List<SObject>());

        rflib_BigObjectQueryController.QueryCursor cursor = new rflib_BigObjectQueryController.QueryCursor();
        cursor.boundaryValue = '200';
        new rflib_DefaultBigObjectQueryService().queryChunk(config, cursor);

        Assert.areEqual(
            new List<Object>{ Decimal.valueOf('100'), Decimal.valueOf('200') },
            rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v2'),
            '300 is ahead of the cursor of a descending field and has been read completely'
        );

        config.filters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createIn('CloseDate', new List<String>{ '2026-09-01', '2026-10-01', '2026-11-01' })
        };
        cursor.boundaryValue = '2026-10-01';
        new rflib_DefaultBigObjectQueryService().queryChunk(config, cursor);

        Assert.areEqual(
            new List<Object>{ Date.newInstance(2026, 10, 1), Date.newInstance(2026, 11, 1) },
            rflib_DefaultBigObjectQueryService.lastQueryBinding.get('v1')
        );
    }

    private static rflib_BigObjectQueryController.ResolvedConfig createConfig(String direction, Integer chunkSize) {
        rflib_BigObjectQueryController.ResolvedConfig config = new rflib_BigObjectQueryController.ResolvedConfig();
        config.objectApiName = 'rflib_Application_Event_Archive__b';
        config.indexFields = INDEX_FIELDS;
        config.indexDirections = new List<String>{ direction, 'ASC', 'ASC', 'ASC' };
        config.queryFields = new List<String>(INDEX_FIELDS);
        config.queryFields.add('Additional_Details__c');
        config.chunkSize = chunkSize;

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.rflib_Application_Event_Archive__b.fields.getMap();
        for (String fieldName : config.queryFields) {
            config.fieldDescribes.put(fieldName, fieldMap.get(fieldName.toLowerCase()).getDescribe());
        }
        return config;
    }

    private static rflib_BigObjectQueryController.QueryCursor createCursor(
        Datetime boundary,
        List<String> seenKeys,
        Integer recordsLoaded
    ) {
        rflib_BigObjectQueryController.QueryCursor cursor = new rflib_BigObjectQueryController.QueryCursor();
        cursor.boundaryValue = iso(boundary);
        cursor.seenKeys = seenKeys;
        cursor.recordsLoaded = recordsLoaded;
        return cursor;
    }

    private static rflib_BigObjectQueryController.IndexFilter createEquals(String fieldName, String value) {
        rflib_BigObjectQueryController.IndexFilter filter = new rflib_BigObjectQueryController.IndexFilter();
        filter.fieldName = fieldName;
        filter.operator = rflib_BigObjectQueryController.OPERATOR_EQUALS;
        filter.value = value;
        return filter;
    }

    private static rflib_BigObjectQueryController.IndexFilter createRange(
        String fieldName,
        Datetime fromValue,
        Datetime toValue
    ) {
        rflib_BigObjectQueryController.IndexFilter filter = new rflib_BigObjectQueryController.IndexFilter();
        filter.fieldName = fieldName;
        filter.operator = rflib_BigObjectQueryController.OPERATOR_RANGE;
        filter.fromValue = iso(fromValue);
        filter.toValue = iso(toValue);
        return filter;
    }

    private static rflib_BigObjectQueryController.IndexFilter createIn(String fieldName, List<String> values) {
        rflib_BigObjectQueryController.IndexFilter filter = new rflib_BigObjectQueryController.IndexFilter();
        filter.fieldName = fieldName;
        filter.operator = rflib_BigObjectQueryController.OPERATOR_IN;
        filter.values = values;
        return filter;
    }

    private static rflib_Application_Event_Archive__b createRecord(Datetime occurredOn, String eventName) {
        return new rflib_Application_Event_Archive__b(
            Occurred_On__c = occurredOn,
            Event_Name__c = eventName,
            Related_Record_ID__c = 'REL',
            Created_By_ID__c = 'USER',
            Additional_Details__c = '{"event":"' + eventName + '"}'
        );
    }

    private static String createKey(rflib_Application_Event_Archive__b record) {
        return JSON.serialize(
            new List<String>{
                iso(record.Occurred_On__c),
                record.Event_Name__c,
                record.Related_Record_ID__c,
                record.Created_By_ID__c
            }
        );
    }

    private static String iso(Datetime value) {
        return rflib_BigObjectQueryController.formatValue(Schema.DisplayType.DATETIME, value);
    }
}
