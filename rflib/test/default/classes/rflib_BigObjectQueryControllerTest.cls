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
private class rflib_BigObjectQueryControllerTest {
    private static final String ARCHIVE = 'rflib_Application_Event_Archive__b';

    // Only required fields, which are readable for every user with object access, so the user mode tests do not
    // depend on the field level security of the running user.
    private static final List<String> INDEX_FIELDS = new List<String>{
        'Occurred_On__c',
        'Event_Name__c',
        'Related_Record_ID__c',
        'Created_By_ID__c'
    };

    @IsTest
    private static void testDescribeConfig_ResolvesFieldsAndDefaultFilter() {
        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(
            createConfig()
        );

        Assert.isTrue(result.isValid, String.valueOf(result.problems));
        Assert.areEqual(ARCHIVE, result.objectApiName);
        Assert.areEqual('Application Event Archive', result.objectLabel);
        Assert.areEqual(INDEX_FIELDS, result.indexFields);
        Assert.areEqual(new List<String>{ 'Occurred_On__c', 'Event_Name__c' }, result.displayFields);
        Assert.areEqual(1, result.filterableIndexDepth);
        Assert.isTrue(result.droppedFields.isEmpty());

        Assert.areEqual(4, result.fields.size(), 'The query fields are the union of all field lists');
        Assert.areEqual('Occurred_On__c', result.fields[0].apiName);
        Assert.areEqual('datetime', result.fields[0].dataType);
        Assert.areEqual('Occurred On', result.fields[0].label);
        Assert.areEqual('text', result.fields[1].dataType);

        Date today = Datetime.now().dateGmt();
        Assert.areEqual(1, result.defaultFilters.size(), 'A date-led index defaults to the last seven days');
        rflib_BigObjectQueryController.IndexFilter defaultFilter = result.defaultFilters[0];
        Assert.areEqual('Occurred_On__c', defaultFilter.fieldName);
        Assert.areEqual(rflib_BigObjectQueryController.OPERATOR_RANGE, defaultFilter.operator);
        Assert.areEqual(
            iso(Datetime.newInstanceGmt(today.addDays(-7), Time.newInstance(0, 0, 0, 0))),
            defaultFilter.fromValue
        );
        Assert.areEqual(iso(Datetime.newInstanceGmt(today, Time.newInstance(23, 59, 59, 999))), defaultFilter.toValue);
    }

    @IsTest
    private static void testDescribeConfig_CanonicalizesFieldNamesAndRemovesDuplicates() {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.bigObjectApiName = ARCHIVE.toLowerCase();
        config.displayFields = new List<String>{ ' occurred_on__c ', 'EVENT_NAME__C', 'event_name__c', '' };

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isTrue(result.isValid, String.valueOf(result.problems));
        Assert.areEqual(ARCHIVE, result.objectApiName);
        Assert.areEqual(new List<String>{ 'Occurred_On__c', 'Event_Name__c' }, result.displayFields);
    }

    @IsTest
    private static void testDescribeConfig_BlankDetailFieldsShowEveryCustomField() {
        // A reader with the access permission set can read Additional_Details__c, whatever the running user holds.
        User reader = rflib_TestUserFactory.insertAndRetrieve('Bea', 'Blank', 'Standard User');
        insert new PermissionSetAssignment(
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'rflib_Big_Object_Explorer_Access']
            .Id,
            AssigneeId = reader.Id
        );
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.detailFields = new List<String>{ ' ' };

        rflib_BigObjectQueryController.ConfigDescription result;
        System.runAs(reader) {
            result = rflib_BigObjectQueryController.describeConfig(config);
        }

        List<String> expected = new List<String>(INDEX_FIELDS);
        expected.add('Additional_Details__c');
        Assert.areEqual(expected, result.detailFields, 'Index fields lead, the other custom fields follow');
        Assert.areEqual('longtext', result.fields[4].dataType);
    }

    @IsTest
    private static void testDescribeConfig_RejectsInvalidObjects() {
        assertSingleProblem(null, 'bigObjectApiName', 'required');
        assertSingleProblem('Account', 'bigObjectApiName', 'not a Big Object');
        assertSingleProblem('Does_Not_Exist__b', 'bigObjectApiName', 'does not exist');
    }

    @IsTest
    private static void testDescribeConfig_ReportsFieldProblems() {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.indexFields = new List<String>();
        config.displayFields = new List<String>{ 'Unknown__c' };

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isFalse(result.isValid);
        Assert.isTrue(hasProblem(result, 'indexFields', 'At least one index field'), String.valueOf(result.problems));
        Assert.isTrue(hasProblem(result, 'displayFields', 'Unknown__c'), String.valueOf(result.problems));
        Assert.isTrue(
            hasProblem(result, 'displayFields', 'At least one display field'),
            String.valueOf(result.problems)
        );
    }

    @IsTest
    private static void testDescribeConfig_ReportsInvalidNumbersAndDirections() {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.sortDirection = 'DOWN,ASC,ASC,ASC,ASC';
        config.chunkSize = 50001;
        config.filterableIndexDepth = 5;

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isTrue(hasProblem(result, 'indexSortDirection', 'DOWN'), String.valueOf(result.problems));
        Assert.isTrue(
            hasProblem(result, 'indexSortDirection', 'more sort directions'),
            String.valueOf(result.problems)
        );
        Assert.isTrue(hasProblem(result, 'chunkSize', '50000'), String.valueOf(result.problems));
        Assert.isTrue(hasProblem(result, 'filterableIndexDepth', '(4)'), String.valueOf(result.problems));

        config = createConfig();
        config.chunkSize = 0;
        config.filterableIndexDepth = 0;
        result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isTrue(hasProblem(result, 'chunkSize', 'between 1'), String.valueOf(result.problems));
        Assert.isTrue(hasProblem(result, 'filterableIndexDepth', 'between 1'), String.valueOf(result.problems));
    }

    @IsTest
    private static void testDescribeConfig_ParsesTheFilterGrammar() {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.filterableIndexDepth = 2;
        config.defaultFilter = 'Occurred_On__c=2026-10-01T00:00:00Z ; event_name__c=LOGIN, LOGOUT';

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isTrue(result.isValid, String.valueOf(result.problems));
        Assert.areEqual(2, result.defaultFilters.size());
        Assert.areEqual(rflib_BigObjectQueryController.OPERATOR_EQUALS, result.defaultFilters[0].operator);
        Assert.areEqual('2026-10-01T00:00:00Z', result.defaultFilters[0].value);
        Assert.areEqual('Event_Name__c', result.defaultFilters[1].fieldName);
        Assert.areEqual(rflib_BigObjectQueryController.OPERATOR_IN, result.defaultFilters[1].operator);
        Assert.areEqual(new List<String>{ 'LOGIN', 'LOGOUT' }, result.defaultFilters[1].values);

        config.defaultFilter = 'Occurred_On__c=2026-10-01T00:00:00Z..';
        rflib_BigObjectQueryController.IndexFilter openRange = rflib_BigObjectQueryController.describeConfig(config)
            .defaultFilters[0];
        Assert.areEqual(rflib_BigObjectQueryController.OPERATOR_RANGE, openRange.operator);
        Assert.areEqual('2026-10-01T00:00:00Z', openRange.fromValue);
        Assert.isNull(openRange.toValue);

        config.defaultFilter = 'Occurred_On__c=2026-10-01';
        Assert.isTrue(
            rflib_BigObjectQueryController.describeConfig(config).isValid,
            'A plain date is accepted for a datetime field'
        );
    }

    @IsTest
    private static void testDescribeConfig_ResolvesRelativeDates() {
        Date today = Datetime.now().dateGmt();
        assertRelativeWindow('TODAY', today, today);
        assertRelativeWindow('yesterday', today.addDays(-1), today.addDays(-1));
        assertRelativeWindow('THIS_MONTH', today.toStartOfMonth(), today.toStartOfMonth().addMonths(1).addDays(-1));
        assertRelativeWindow('LAST_N_DAYS:30', today.addDays(-30), today);
    }

    @IsTest
    private static void testDescribeConfig_RejectsIllegalFilters() {
        assertFilterProblem('Event_Name__c=LOGIN', 1, 'does not follow the index order');
        assertFilterProblem('Unknown__c=1', 1, 'does not follow the index order');
        assertFilterProblem('Occurred_On__c=LAST_N_DAYS:7;Event_Name__c=LOGIN', 2, 'must be an exact value');
        assertFilterProblem(
            'Occurred_On__c=2026-10-01T00:00:00Z;Event_Name__c=LOGIN',
            1,
            'beyond the filterable index depth'
        );
        assertFilterProblem('Occurred_On__c', 1, 'not in the form Field=value');
        assertFilterProblem('Occurred_On__c=soon', 1, 'invalid value');
        assertFilterProblem('Occurred_On__c=..', 1, 'has no value');
    }

    @IsTest
    private static void testDescribeConfig_NoDefaultFilterForAnIndexThatDoesNotLeadWithADate() {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.indexFields = new List<String>{ 'Event_Name__c' };

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isTrue(result.isValid, String.valueOf(result.problems));
        Assert.isTrue(result.defaultFilters.isEmpty());
    }

    @IsTest
    private static void testDescribeConfig_RejectsUsersWithoutObjectAccess() {
        User standardUser = rflib_TestUserFactory.insertAndRetrieve('Ned', 'NoAccess', 'Standard User');

        rflib_BigObjectQueryController.ConfigDescription result;
        System.runAs(standardUser) {
            result = rflib_BigObjectQueryController.describeConfig(createConfig());
        }

        Assert.isFalse(result.isValid);
        Assert.isTrue(
            hasProblem(result, 'bigObjectApiName', 'You do not have read access'),
            String.valueOf(result.problems)
        );
    }

    @IsTest
    private static void testDescribeConfig_GrantsTheArchiveThroughTheAccessPermissionSet() {
        User reader = rflib_TestUserFactory.insertAndRetrieve('Rita', 'Reader', 'Standard User');
        insert new PermissionSetAssignment(
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'rflib_Big_Object_Explorer_Access']
            .Id,
            AssigneeId = reader.Id
        );

        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.detailFields = new List<String>{ 'Occurred_On__c', 'Additional_Details__c' };

        rflib_BigObjectQueryController.ConfigDescription result;
        System.runAs(reader) {
            result = rflib_BigObjectQueryController.describeConfig(config);
        }

        Assert.isTrue(result.isValid, String.valueOf(result.problems));
        Assert.isTrue(result.droppedFields.isEmpty(), String.valueOf(result.droppedFields));
        Assert.areEqual(new List<String>{ 'Occurred_On__c', 'Additional_Details__c' }, result.detailFields);
    }

    @IsTest
    private static void testDescribeConfig_DropsFieldsTheUserCannotRead() {
        User reader = rflib_TestUserFactory.insertAndRetrieve('Dora', 'Dropped', 'Standard User');

        PermissionSet permissionSet = new PermissionSet(Name = 'rflibBigObjectReaderTest', Label = 'Big Object Reader');
        insert permissionSet;
        insert new ObjectPermissions(ParentId = permissionSet.Id, SobjectType = ARCHIVE, PermissionsRead = true);
        insert new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = reader.Id);

        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.detailFields = new List<String>{ 'Occurred_On__c', 'Additional_Details__c' };

        rflib_BigObjectQueryController.ConfigDescription result;
        System.runAs(reader) {
            result = rflib_BigObjectQueryController.describeConfig(config);
        }

        Assert.isTrue(result.isValid, String.valueOf(result.problems));
        Assert.areEqual(new List<String>{ 'Additional_Details__c' }, result.droppedFields);
        Assert.areEqual(new List<String>{ 'Occurred_On__c' }, result.detailFields);
    }

    @IsTest
    private static void testQueryChunk_RunsInUserModeForAnOpsCenterUser() {
        User opsUser = rflib_TestUserFactory.insertAndRetrieve('Owen', 'Ops', 'Standard User');
        insert new PermissionSetAssignment(
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'rflib_Ops_Center_Access']
            .Id,
            AssigneeId = opsUser.Id
        );

        // No mock: the real Big Object query runs in user mode for a user without admin permissions. A window
        // long before any archived event keeps the result independent of the org's data.
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.detailFields = new List<String>{ 'Additional_Details__c' };
        config.indexFilters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createRange('Occurred_On__c', '2001-01-01T00:00:00Z', '2001-01-02T00:00:00Z')
        };

        rflib_BigObjectQueryController.ChunkResult result;
        System.runAs(opsUser) {
            result = rflib_BigObjectQueryController.queryChunk(config, null);
        }

        Assert.isTrue(result.isComplete);
        Assert.isTrue(result.records.isEmpty());
    }

    @IsTest
    private static void testQueryChunk_PassesTheValidatedConfigToTheService() {
        StubQueryService service = new StubQueryService(null);
        rflib_BigObjectQueryController.QUERY_SERVICE = service;

        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.indexFilters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createRange('occurred_on__c', '2026-10-01T00:00:00Z', null)
        };
        rflib_BigObjectQueryController.QueryCursor cursor = new rflib_BigObjectQueryController.QueryCursor();

        rflib_BigObjectQueryController.ChunkResult result = rflib_BigObjectQueryController.queryChunk(config, cursor);

        Assert.areEqual(service.result, result);
        Assert.areEqual(cursor, service.capturedCursor);
        Assert.areEqual(ARCHIVE, service.capturedConfig.objectApiName);
        Assert.areEqual(INDEX_FIELDS, service.capturedConfig.queryFields);
        Assert.areEqual(new List<String>{ 'DESC', 'ASC', 'ASC', 'ASC' }, service.capturedConfig.indexDirections);
        Assert.areEqual(2000, service.capturedConfig.chunkSize);
        Assert.areEqual(1, service.capturedConfig.filters.size());
        Assert.areEqual('Occurred_On__c', service.capturedConfig.filters[0].fieldName);
    }

    @IsTest
    private static void testQueryChunk_RejectsAnIllegalFilterFromTheClient() {
        StubQueryService service = new StubQueryService(null);
        rflib_BigObjectQueryController.QUERY_SERVICE = service;

        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.filterableIndexDepth = 2;
        config.indexFilters = new List<rflib_BigObjectQueryController.IndexFilter>{
            createRange('Occurred_On__c', '2026-10-01T00:00:00Z', null),
            createRange('Event_Name__c', 'A', 'B')
        };

        String message = assertQueryChunkFails(config);
        Assert.isTrue(message.contains('indexFilters'), message);
        Assert.isTrue(message.contains('must be an exact value'), message);
        Assert.isNull(service.capturedConfig, 'The service is never called');
    }

    @IsTest
    private static void testQueryChunk_RejectsAnInvalidConfig() {
        rflib_BigObjectQueryController.QUERY_SERVICE = new StubQueryService(null);
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.bigObjectApiName = 'Account';

        String message = assertQueryChunkFails(config);
        Assert.isTrue(message.contains('bigObjectApiName'), message);
    }

    @IsTest
    private static void testQueryChunk_QueryFailureNamesTheIndexFieldsAttribute() {
        rflib_BigObjectQueryController.QUERY_SERVICE = new StubQueryService(
            new QueryException('Invalid Big Object query')
        );

        String message = assertQueryChunkFails(createConfig());
        Assert.isTrue(message.contains('Invalid Big Object query'), message);
        Assert.isTrue(message.contains('indexFields'), message);
    }

    @IsTest
    private static void testQueryChunk_OtherFailuresKeepTheirMessage() {
        rflib_BigObjectQueryController.QUERY_SERVICE = new StubQueryService(
            new rflib_InvalidStateException('Something broke')
        );

        Assert.areEqual('Something broke', assertQueryChunkFails(createConfig()));
    }

    @IsTest
    private static void testParseAndFormatValue() {
        String isoValue = '2026-10-01T12:34:56.789Z';
        Assert.areEqual(
            isoValue,
            iso((Datetime) rflib_BigObjectQueryController.parseValue(Schema.DisplayType.DATETIME, isoValue)),
            'A datetime survives the round trip with millisecond precision'
        );
        Assert.areEqual(
            Datetime.newInstanceGmt(2026, 10, 1, 0, 0, 0),
            rflib_BigObjectQueryController.parseValue(Schema.DisplayType.DATETIME, '2026-10-01')
        );
        Assert.areEqual(
            Date.newInstance(2026, 10, 1),
            rflib_BigObjectQueryController.parseValue(Schema.DisplayType.DATE, '2026-10-01')
        );
        Assert.areEqual(
            Decimal.valueOf('12.5'),
            rflib_BigObjectQueryController.parseValue(Schema.DisplayType.DOUBLE, ' 12.5 ')
        );
        Assert.areEqual('abc', rflib_BigObjectQueryController.parseValue(Schema.DisplayType.STRING, ' abc '));
        Assert.isNull(rflib_BigObjectQueryController.parseValue(Schema.DisplayType.STRING, ' '));
        Assert.isNull(rflib_BigObjectQueryController.formatValue(Schema.DisplayType.STRING, null));
        Assert.areEqual(
            '2026-10-01',
            rflib_BigObjectQueryController.formatValue(Schema.DisplayType.DATE, Date.newInstance(2026, 10, 1))
        );

        try {
            rflib_BigObjectQueryController.parseValue(Schema.DisplayType.INTEGER, 'ten');
            Assert.fail('Expected exception has not been thrown');
        } catch (rflib_InvalidArgumentException ex) {
            Assert.isTrue(ex.getMessage().contains('ten'), ex.getMessage());
        }
    }

    private static rflib_BigObjectQueryController.ExplorerConfig createConfig() {
        rflib_BigObjectQueryController.ExplorerConfig config = new rflib_BigObjectQueryController.ExplorerConfig();
        config.bigObjectApiName = ARCHIVE;
        config.indexFields = new List<String>(INDEX_FIELDS);
        config.sortDirection = 'DESC';
        config.displayFields = new List<String>{ 'Occurred_On__c', 'Event_Name__c' };
        config.detailFields = new List<String>(INDEX_FIELDS);
        return config;
    }

    private static rflib_BigObjectQueryController.IndexFilter createRange(
        String fieldName,
        String fromValue,
        String toValue
    ) {
        rflib_BigObjectQueryController.IndexFilter filter = new rflib_BigObjectQueryController.IndexFilter();
        filter.fieldName = fieldName;
        filter.operator = rflib_BigObjectQueryController.OPERATOR_RANGE;
        filter.fromValue = fromValue;
        filter.toValue = toValue;
        return filter;
    }

    private static void assertSingleProblem(String objectApiName, String attribute, String messagePart) {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.bigObjectApiName = objectApiName;

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isFalse(result.isValid);
        Assert.areEqual(1, result.problems.size(), String.valueOf(result.problems));
        Assert.isTrue(hasProblem(result, attribute, messagePart), String.valueOf(result.problems));
    }

    private static void assertRelativeWindow(String literal, Date expectedFrom, Date expectedTo) {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.defaultFilter = 'Occurred_On__c=' + literal;

        rflib_BigObjectQueryController.IndexFilter filter = rflib_BigObjectQueryController.describeConfig(config)
            .defaultFilters[0];

        Assert.areEqual(
            iso(Datetime.newInstanceGmt(expectedFrom, Time.newInstance(0, 0, 0, 0))),
            filter.fromValue,
            literal
        );
        Assert.areEqual(
            iso(Datetime.newInstanceGmt(expectedTo, Time.newInstance(23, 59, 59, 999))),
            filter.toValue,
            literal
        );
    }

    private static void assertFilterProblem(String defaultFilter, Integer depth, String messagePart) {
        rflib_BigObjectQueryController.ExplorerConfig config = createConfig();
        config.defaultFilter = defaultFilter;
        config.filterableIndexDepth = depth;

        rflib_BigObjectQueryController.ConfigDescription result = rflib_BigObjectQueryController.describeConfig(config);

        Assert.isFalse(result.isValid, defaultFilter);
        Assert.isTrue(hasProblem(result, 'defaultFilter', messagePart), defaultFilter + ': ' + result.problems);
    }

    private static String assertQueryChunkFails(rflib_BigObjectQueryController.ExplorerConfig config) {
        try {
            rflib_BigObjectQueryController.queryChunk(config, null);
            Assert.fail('Expected exception has not been thrown');
        } catch (AuraHandledException ex) {
            return ex.getMessage();
        }
        return null;
    }

    private static Boolean hasProblem(
        rflib_BigObjectQueryController.ConfigDescription result,
        String attribute,
        String messagePart
    ) {
        for (rflib_BigObjectQueryController.ConfigProblem problem : result.problems) {
            if (problem.attribute == attribute && problem.message.contains(messagePart)) {
                return true;
            }
        }
        return false;
    }

    private class StubQueryService implements rflib_BigObjectQueryService {
        public rflib_BigObjectQueryController.ResolvedConfig capturedConfig;
        public rflib_BigObjectQueryController.QueryCursor capturedCursor;
        public rflib_BigObjectQueryController.ChunkResult result;
        private final Exception failure;

        public StubQueryService(Exception failure) {
            this.failure = failure;
            this.result = new rflib_BigObjectQueryController.ChunkResult();
            this.result.records = new List<SObject>{ new rflib_Application_Event_Archive__b(Event_Name__c = 'A') };
            this.result.cursor = new rflib_BigObjectQueryController.QueryCursor();
            this.result.cursor.recordsLoaded = 1;
            this.result.isComplete = true;
            this.result.isStuck = false;
        }

        public rflib_BigObjectQueryController.ChunkResult queryChunk(
            rflib_BigObjectQueryController.ResolvedConfig config,
            rflib_BigObjectQueryController.QueryCursor cursor
        ) {
            this.capturedConfig = config;
            this.capturedCursor = cursor;
            if (failure != null) {
                throw failure;
            }
            return result;
        }
    }

    private static String iso(Datetime value) {
        return rflib_BigObjectQueryController.formatValue(Schema.DisplayType.DATETIME, value);
    }
}
