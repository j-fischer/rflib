/**
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/soql-lib/blob/main/LICENSE)
 *
 * v6.13.0
 *
 * PMD False Positives:
 * - ExcessivePublicCount: It is a library class and exposes all necessary methods to construct a query
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE class
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE class
 * - PropertyNamingConventions: It was intentional to make the lib more fluent and readable
 * - FieldDeclarationsShouldBeAtStart: Developer who uses lib should see what's important at start
 * - ApexDoc: Variable names are self-documented.
 * - FieldNamingConventions: It was intentional to make the lib more fluent and readable
 * - ExcessiveParameterList: Make methods similar to native rflib_SOQL
 * - NcssTypeCount: It is a library and we tried to put everything into ONE class
 * - NcssCount: It is a library and we tried to put everything into ONE class
 **/
@NamespaceAccessible
@SuppressWarnings(
    'PMD.ExcessivePublicCount,PMD.ExcessiveClassLength,PMD.FieldNamingConventions,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.PropertyNamingConventions,PMD.FieldDeclarationsShouldBeAtStart,PMD.ApexDoc,PMD.ExcessiveParameterList,PMD.NcssTypeCount,PMD.NcssCount'
)
public virtual inherited sharing class rflib_SOQL implements Queryable {
    @NamespaceAccessible
    public interface Selector {
        Queryable query();
    }

    @NamespaceAccessible
    public static Queryable of(SObjectType ofObject) {
        return new rflib_SOQL(ofObject);
    }

    @NamespaceAccessible
    public static Queryable of(String ofObject) {
        return new rflib_SOQL(ofObject);
    }

    @NamespaceAccessible
    public interface Queryable {
        // SELECT
        Queryable with(SObjectField field);
        Queryable with(SObjectField field1, SObjectField field2);
        Queryable with(SObjectField field1, SObjectField field2, SObjectField field3);
        Queryable with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Queryable with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        Queryable with(List<SObjectField> fields);
        Queryable with(Iterable<String> fields);
        Queryable with(String fields);
        Queryable with(SObjectField field, String alias);
        Queryable with(String relationshipName, SObjectField field);
        Queryable with(String relationshipName, SObjectField field1, SObjectField field2);
        Queryable with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3);
        Queryable with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Queryable with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        Queryable with(String relationshipName, Iterable<SObjectField> fields);
        Queryable with(SubQuery subQuery);
        Queryable with(TypeOf typeOf);
        Queryable withFieldSet(String fieldSetName);
        // SELECT - AGGREGATE FUNCTIONS
        Queryable count();
        Queryable count(SObjectField field);
        Queryable count(SObjectField field, String alias);
        Queryable count(String relationshipName, SObjectField field);
        Queryable count(String relationshipName, SObjectField field, String alias);
        Queryable avg(SObjectField field);
        Queryable avg(SObjectField field, String alias);
        Queryable avg(String relationshipName, SObjectField field);
        Queryable avg(String relationshipName, SObjectField field, String alias);
        Queryable countDistinct(SObjectField field);
        Queryable countDistinct(SObjectField field, String alias);
        Queryable countDistinct(String relationshipName, SObjectField field);
        Queryable countDistinct(String relationshipName, SObjectField field, String alias);
        Queryable min(SObjectField field);
        Queryable min(SObjectField field, String alias);
        Queryable min(String relationshipName, SObjectField field);
        Queryable min(String relationshipName, SObjectField field, String alias);
        Queryable max(SObjectField field);
        Queryable max(SObjectField field, String alias);
        Queryable max(String relationshipName, SObjectField field);
        Queryable max(String relationshipName, SObjectField field, String alias);
        Queryable sum(SObjectField field);
        Queryable sum(SObjectField field, String alias);
        Queryable sum(String relationshipName, SObjectField field);
        Queryable sum(String relationshipName, SObjectField field, String alias);
        // SELECT - GROUPING
        Queryable grouping(SObjectField field, String alias);
        // SELECT - toLabel
        Queryable toLabel(SObjectField field);
        Queryable toLabel(SObjectField field, String alias);
        Queryable toLabel(String field);
        Queryable toLabel(String field, String alias);
        Queryable toLabel(Iterable<String> fields);
        // SELECT - FORMAT
        Queryable format(SObjectField field);
        Queryable format(SObjectField field, String alias);
        // USING SCOPE
        Queryable delegatedScope();
        Queryable mineScope();
        Queryable mineAndMyGroupsScope();
        Queryable myTerritoryScope();
        Queryable myTeamTerritoryScope();
        Queryable teamScope();
        // WHERE
        Queryable whereAre(FilterGroup filterGroup);
        Queryable whereAre(Filter filter);
        Queryable whereAre(String conditions);
        Queryable conditionLogic(String order);
        Queryable anyConditionMatching();
        // PREDEFINED WHERE
        Queryable byId(SObject record);
        Queryable byId(Id recordId);
        Queryable byIds(Iterable<Id> recordIds);
        Queryable byIds(List<SObject> records);
        Queryable byRecordType(String recordTypeDeveloperName);
        // GROUP BY
        Queryable groupBy(SObjectField field);
        Queryable groupBy(String field);
        Queryable groupBy(String relationshipName, SObjectField field);
        Queryable groupByRollup(SObjectField field);
        Queryable groupByRollup(String relationshipName, SObjectField field);
        Queryable groupByCube(SObjectField field);
        Queryable groupByCube(String relationshipName, SObjectField field);
        // HAVING
        Queryable have(HavingFilterGroup havingFilterGroup);
        Queryable have(HavingFilter havingFilter);
        Queryable have(String havingConditions);
        Queryable havingConditionLogic(String havingConditionsOrder);
        Queryable anyHavingConditionMatching();
        // WITH DATA CATEGORY
        Queryable withDataCategory(DataCategoryFilter dataCategoryFilter);
        // ORDER BY
        Queryable orderBy(SObjectField field);
        Queryable orderBy(String field);
        Queryable orderBy(String field, String direction);
        Queryable orderBy(String relationshipName, SObjectField field);
        Queryable orderByCount(SObjectField field);
        Queryable orderBy(Distance distance);
        Queryable sortDesc();
        Queryable sort(String direction);
        Queryable nullsLast();
        Queryable nullsOrder(String nullsOrder);
        // LIMIT
        Queryable setLimit(Integer amount);
        // OFFSET
        Queryable offset(Integer startingRow);
        // FOR
        Queryable forReference();
        Queryable forView();
        Queryable forUpdate();
        Queryable allRows();
        // FIELD-LEVEL SECURITY
        Queryable userMode();
        Queryable systemMode();
        Queryable stripInaccessible();
        Queryable stripInaccessible(AccessType accessType);
        // SHARING MODE
        Queryable withSharing();
        Queryable withoutSharing();
        // MOCKING
        Queryable mockId(String queryIdentifier);
        // DEBUGGING
        Queryable preview();
        // SOBJECT
        SObject toObject();
        // LIST
        List<SObject> toList();
        // COUNT
        Integer toInteger();
        // QUERY LOCATOR
        Database.QueryLocator toQueryLocator();
        // CURSOR
        Database.Cursor toCursor();
        Database.PaginationCursor toPaginationCursor();
        // DO EXIST
        Boolean doExist();
        // AGGREGATE RESULTS
        List<AggregateResult> toAggregated();
        List<rflib_SOQL.AggregateResultProxy> toAggregatedProxy(); // use when you need mocking
        // STRING
        String toString();
        // IDS
        Id toId();
        Set<Id> toIds();
        Set<Id> toIdsOf(SObjectField field);
        Set<Id> toIdsOf(String relationshipName, SObjectField targetKeyField);
        // VALUE
        Object toValueOf(SObjectField fieldToExtract);
        Set<String> toValuesOf(SObjectField fieldToExtract);
        Set<String> toValuesOf(String relationshipName, SObjectField targetKeyField);
        // ID MAP
        Map<Id, SObject> toMap();
        Map<Id, SObject> toIdMapBy(SObjectField field);
        Map<Id, SObject> toIdMapBy(String relationshipName, SObjectField targetKeyField);
        Map<Id, List<SObject>> toAggregatedIdMapBy(SObjectField keyField);
        Map<Id, List<SObject>> toAggregatedIdMapBy(String relationshipName, SObjectField targetKeyField);
        // VALUE MAP
        Map<String, SObject> toMap(SObjectField keyField);
        Map<String, SObject> toMap(String relationshipName, SObjectField targetKeyField);
        Map<String, String> toMap(SObjectField keyField, SObjectField valueField);
        Map<String, String> toMap(SObjectField keyField, String relationshipName, SObjectField targetKeyField);
        Map<String, List<SObject>> toAggregatedMap(SObjectField keyField);
        Map<String, List<SObject>> toAggregatedMap(String relationshipName, SObjectField targetKeyField);
        Map<String, List<String>> toAggregatedMap(SObjectField keyField, SObjectField valueField);
        Map<String, List<String>> toAggregatedMap(SObjectField keyField, String relationshipName, SObjectField targetKeyField);

        // for internal use
        Map<String, Object> binding();
    }

    @NamespaceAccessible
    public interface SubQuery {
        SubQuery of(String ofObject);
        // SELECT
        SubQuery with(SObjectField field);
        SubQuery with(SObjectField field1, SObjectField field2);
        SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3);
        SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        SubQuery with(Iterable<SObjectField> fields);
        SubQuery with(String fields);
        SubQuery with(String relationshipName, SObjectField field);
        SubQuery with(String relationshipName, SObjectField field1, SObjectField field2);
        SubQuery with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3);
        SubQuery with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        SubQuery with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        SubQuery with(String relationshipName, Iterable<SObjectField> fields);
        SubQuery with(SubQuery subQuery);
        SubQuery toLabel(SObjectField field);
        SubQuery toLabel(SObjectField field, String alias);
        SubQuery toLabel(String field);
        SubQuery toLabel(String field, String alias);
        SubQuery toLabel(Iterable<String> fields);
        // WHERE
        SubQuery whereAre(FilterGroup filterGroup);
        SubQuery whereAre(Filter filter);
        // ORDER BY
        SubQuery orderBy(SObjectField field);
        SubQuery orderBy(String field);
        SubQuery orderBy(String relationshipName, SObjectField field);
        SubQuery orderBy(Distance distance);
        SubQuery sortDesc();
        SubQuery sort(String direction);
        SubQuery nullsLast();
        // LIMIT
        SubQuery setLimit(Integer amount);
        // OFFSET
        SubQuery offset(Integer startingRow);
        // FOR
        SubQuery forReference();
        SubQuery forView();
        // ADDITIONAL
        String getChildRelationshipName();
    }

    @NamespaceAccessible
    public interface TypeOf {
        TypeOf of(String ofField);
        TypeOf of(SObjectField ofField);
        // WHEN
        TypeOf when(SObjectType whenObject);
        // THEN
        TypeOf then(SObjectField field);
        TypeOf then(SObjectField field1, SObjectField field2);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        TypeOf then(List<SObjectField> fields);
        TypeOf then(Iterable<String> fields);
        TypeOf then(String fields);
        TypeOf then(String relationshipName, SObjectField field);
        TypeOf then(String relationshipName, SObjectField field1, SObjectField field2);
        TypeOf then(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3);
        TypeOf then(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        TypeOf then(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        TypeOf then(String relationshipName, Iterable<SObjectField> fields);
        // ELSE
        TypeOf whenElse(Iterable<String> fields);
        TypeOf whenElse(String fields);
    }

    @NamespaceAccessible
    public interface FilterGroup {
        // ADD CONDITION
        FilterGroup add(FilterGroup filterGroup);
        FilterGroup add(Filter filter);
        FilterGroup add(String dynamicCondition);
        FilterGroup add(List<Filter> filters);
        FilterGroup add(List<String> dynamicConditions);
        // ORDER
        FilterGroup anyConditionMatching();
        FilterGroup conditionLogic(String order);
        // ADDITIONAL
        FilterGroup ignoreWhen(Boolean logicExpression);

        Boolean hasValues();
    }

    @NamespaceAccessible
    public interface Filter {
        // FIELDS
        Filter id();
        Filter recordType();
        Filter name();
        Filter with(SObjectField field);
        Filter with(String field);
        Filter with(String relationshipName, SObjectField field);
        Filter with(Distance distance);
        // COMPARATORS
        Filter isNull();
        Filter isNotNull();
        Filter isTrue();
        Filter isFalse();
        Filter equal(Object value);
        Filter notEqual(Object value);
        Filter lessThan(Object value);
        Filter lessOrEqual(Object value);
        Filter greaterThan(Object value);
        Filter greaterOrEqual(Object value);
        Filter containsSome(Iterable<String> values);
        Filter contains(String value);
        Filter contains(String prefix, String value, String suffix);
        Filter notContains(String value);
        Filter notContains(String prefix, String value, String suffix);
        Filter endsWith(String value);
        Filter notEndsWith(String value);
        Filter startsWith(String value);
        Filter notStartsWith(String value);
        Filter isIn(Iterable<Object> iterable);
        Filter isIn(InnerJoin joinQuery);
        Filter isIn(Iterable<SObject> sourceRecords, SObjectField sourceKeyField);
        Filter notIn(Iterable<Object> iterable);
        Filter notIn(InnerJoin joinQuery);
        Filter notIn(Iterable<SObject> sourceRecords, SObjectField sourceKeyField);
        Filter includesAll(Iterable<String> values);
        Filter includesSome(Iterable<String> values);
        Filter excludesAll(Iterable<String> values);
        Filter excludesSome(Iterable<String> values);
        // ADDITIONAL
        Filter asDateLiteral();
        Filter ignoreWhen(Boolean logicExpression);

        Boolean hasValue();
    }

    @NamespaceAccessible
    public interface InnerJoin {
        InnerJoin of(SObjectType ofObject);
        // SELECT
        InnerJoin with(SObjectField field);
        // WHERE
        InnerJoin whereAre(FilterGroup filterGroup);
        InnerJoin whereAre(Filter filter);
    }

    @NamespaceAccessible
    public interface HavingFilterGroup {
        // ADD CONDITION
        HavingFilterGroup add(HavingFilterGroup havingFilterGroup);
        HavingFilterGroup add(HavingFilter havingFilter);
        HavingFilterGroup add(String dynamicHaving);
        // ORDER
        HavingFilterGroup anyConditionMatching();
        HavingFilterGroup conditionLogic(String order);

        Boolean hasValues();
    }

    @NamespaceAccessible
    public interface HavingFilter {
        // FIELDS
        HavingFilter with(SObjectField field);
        HavingFilter with(String field);
        HavingFilter count(SObjectField field);
        HavingFilter avg(SObjectField field);
        HavingFilter countDistinct(SObjectField field);
        HavingFilter min(SObjectField field);
        HavingFilter max(SObjectField field);
        HavingFilter sum(SObjectField field);
        // COMPARATORS
        HavingFilter isNull();
        HavingFilter isNotNull();
        HavingFilter isTrue();
        HavingFilter isFalse();
        HavingFilter equal(Object value);
        HavingFilter notEqual(Object value);
        HavingFilter lessThan(Object value);
        HavingFilter lessOrEqual(Object value);
        HavingFilter greaterThan(Object value);
        HavingFilter greaterOrEqual(Object value);
        HavingFilter contains(String value);
        HavingFilter contains(String prefix, String value, String suffix);
        HavingFilter notContains(String value);
        HavingFilter notContains(String prefix, String value, String suffix);
        HavingFilter startsWith(String value);
        HavingFilter notStartsWith(String value);
        HavingFilter endsWith(String value);
        HavingFilter notEndsWith(String value);
        HavingFilter isIn(Iterable<Object> iterable);
        HavingFilter notIn(Iterable<Object> iterable);

        Boolean hasValue();
    }

    @NamespaceAccessible
    public interface DataCategoryFilterGroup {
        DataCategoryFilterGroup add(DataCategoryFilter dataCategoryFilter);
    }

    @NamespaceAccessible
    public interface DataCategoryFilter {
        // FIELDS
        DataCategoryFilter with(String field);
        // COMPARATORS
        DataCategoryFilter at(String category);
        DataCategoryFilter at(Iterable<String> categories);
        DataCategoryFilter above(String category);
        DataCategoryFilter above(Iterable<String> categories);
        DataCategoryFilter below(String category);
        DataCategoryFilter below(Iterable<String> categories);
        DataCategoryFilter aboveOrBelow(String category);
        DataCategoryFilter aboveOrBelow(Iterable<String> categories);

        Boolean hasValue();
    }

    @NamespaceAccessible
    public interface AggregateResultProxy {
        Object get(String field);
        Map<String, Object> getPopulatedFieldsAsMap();
    }

    @NamespaceAccessible
    public interface Distance {
        // field
        Distance of(SObjectField ofField);
        Distance of(String relationship, SObjectField ofField);
        // comparison
        Distance between(System.Location location);
        Distance between(Decimal latitude, Decimal longitude);
        // unit
        Distance mi();
        Distance km();
    }

    @NamespaceAccessible
    public interface Logger {
        void log(Error error);
    }

    @NamespaceAccessible
    public interface Error {
        Exception getException();
        String getQuery();
        Map<String, Object> getBinding();
        AccessLevel getAccessLevel();
    }

    @NamespaceAccessible
    public static SubQuery SubQuery {
        get {
            return new SoqlSubQuery();
        }
    }

    @NamespaceAccessible
    public static TypeOf TypeOf {
        get {
            return new SoqlTypeOf();
        }
    }

    @NamespaceAccessible
    public static FilterGroup FilterGroup {
        get {
            return new SoqlFilterGroup();
        }
    }

    @NamespaceAccessible
    public static Filter Filter {
        get {
            return new SoqlFilter();
        }
    }

    @NamespaceAccessible
    public static InnerJoin InnerJoin {
        get {
            return new SoqlJoinQuery();
        }
    }

    @NamespaceAccessible
    public static HavingFilterGroup HavingFilterGroup {
        get {
            return new SoqlHavingFilterGroup();
        }
    }

    @NamespaceAccessible
    public static HavingFilter HavingFilter {
        get {
            return new SoqlHavingFilter();
        }
    }

    @NamespaceAccessible
    public static DataCategoryFilter DataCategoryFilter {
        get {
            return new SoqlDataCategoryFilter();
        }
    }

    @NamespaceAccessible
    public static Distance Distance {
        get {
            return new SoqlDistance();
        }
    }

    @NamespaceAccessible
    public static Integer getQueries() {
        if (System.Test.isRunningTest() && !System.isBatch() && !System.isFuture() && !System.isQueueable() && !System.isScheduled()) {
            return rflib_SOQL.syncQueriesIssued;
        }

        return Limits.getQueries();
    }

    // Mocking

    @NamespaceAccessible
    public static Mockable mock(SObjectType ofObject) {
        return mock(ofObject.toString().hashCode().toString());
    }

    @NamespaceAccessible
    public static Mockable mock(String mockId) {
        if (!rflib_SOQL.queryIdToMock.containsKey(mockId)) {
            rflib_SOQL.queryIdToMock.put(mockId, new List<SoqlMock>());
        }
        rflib_SOQL.queryIdToMock.get(mockId).add(new SoqlMock());
        return rflib_SOQL.queryIdToMock.get(mockId).get(rflib_SOQL.queryIdToMock.get(mockId).size() - 1);
    }

    public static RandomIdGenerator IdGenerator = new RandomIdGenerator();

    @NamespaceAccessible
    public interface Mockable {
        // SObject
        Mockable thenReturn(SObject record);
        Mockable thenReturn(List<SObject> records);
        // AggregateResultProxy
        Mockable thenReturn(List<Map<String, Object>> aggregatedResults);
        Mockable thenReturn(Map<String, Object> aggregatedResult);
        // Count
        Mockable thenReturn(Integer count);
        // Exception
        void throwException();
        void throwException(String message);
    }

    // Backward support - it's going to be removed in the future

    @TestVisible // deprecated
    private static void setMock(String mockId, SObject record) {
        rflib_SOQL.createLegacyMock(mockId).thenReturn(record);
    }

    @TestVisible // deprecated
    private static void setMock(String mockId, List<SObject> records) {
        rflib_SOQL.createLegacyMock(mockId).thenReturn(records);
    }

    @TestVisible // deprecated
    private static void setCountMock(String mockId, Integer amount) {
        rflib_SOQL.createLegacyMock(mockId).thenReturn(amount);
    }

    private static SoqlMock createLegacyMock(String mockId) {
        SoqlMock mock = new SoqlMock().useLegacyMockingBehavior();
        rflib_SOQL.queryIdToMock.put(mockId, new List<SoqlMock>{ mock });
        return mock;
    }

    // Implementation

    private static Map<String, List<SoqlMock>> queryIdToMock = new Map<String, List<SoqlMock>>();

    private static Binder binder = new Binder();
    private static Integer syncQueriesIssued = 0;

    @TestVisible
    private static Logger queryLogger {
        get {
            if (queryLogger == null) {
                String className = rflib_SOQL.class.getName(); // 'rflib_SOQL' or 'btcdev.rflib_SOQL' when namespaced
                String namespacePrefix = className.contains('.') ? className.substringBefore('.') : null;

                List<ApexTypeImplementor> implementors = [
                    SELECT ClassName, ClassNamespacePrefix
                    FROM ApexTypeImplementor
                    WHERE InterfaceName = 'rflib_SOQL.Logger' AND InterfaceNamespacePrefix = :namespacePrefix AND IsConcrete = TRUE
                    WITH SYSTEM_MODE
                    LIMIT 1
                ];

                if (!implementors.isEmpty()) {
                    Object loggerInstance = Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();
                    queryLogger = loggerInstance instanceof Logger ? (Logger) loggerInstance : null;
                }
            }

            return queryLogger;
        }
        private set;
    }

    private Builder builder;
    private Executor executor;
    private Converter converter;

    @NamespaceAccessible
    public rflib_SOQL(SObjectType ofObject) {
        this(ofObject.toString());
    }

    @NamespaceAccessible
    public rflib_SOQL(String ofObject) {
        this.builder = new Builder(ofObject);
        this.executor = new Executor(builder);
        this.converter = new Converter(ofObject);

        this.mockId(ofObject.hashCode().toString());
    }

    @NamespaceAccessible
    public Queryable with(SObjectField field) {
        this.builder.fields.plainFields.add(field.toString());
        return this;
    }

    @NamespaceAccessible
    public Queryable with(SObjectField field1, SObjectField field2) {
        return this.with(field1).with(field2);
    }

    @NamespaceAccessible
    public Queryable with(SObjectField field1, SObjectField field2, SObjectField field3) {
        return this.with(field1, field2).with(field3);
    }

    @NamespaceAccessible
    public Queryable with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return this.with(field1, field2, field3).with(field4);
    }

    @NamespaceAccessible
    public Queryable with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
        return this.with(field1, field2, field3, field4).with(field5);
    }

    @NamespaceAccessible
    public Queryable with(List<SObjectField> fields) {
        this.builder.fields.plainFields.add(fields);
        return this;
    }

    @NamespaceAccessible
    public Queryable with(Iterable<String> fields) {
        if (!fields.iterator().hasNext()) {
            return this;
        }

        return this.with(String.join(fields, ','));
    }

    @NamespaceAccessible
    public Queryable withFieldSet(String fieldSetName) {
        this.builder.fields.withFieldSet(fieldSetName);
        return this;
    }

    @NamespaceAccessible
    public Queryable with(String fields) {
        this.builder.fields.with(fields);
        return this;
    }

    @NamespaceAccessible
    public Queryable with(SObjectField field, String alias) {
        return this.with(field.toString(), alias);
    }

    private Queryable with(String field, String alias) {
        this.builder.fields.aggregateFields.add(field, alias);
        return this;
    }

    @NamespaceAccessible
    public Queryable with(String relationshipName, SObjectField field) {
        return this.with(relationshipName, new List<SObjectField>{ field });
    }

    @NamespaceAccessible
    public Queryable with(String relationshipName, SObjectField field1, SObjectField field2) {
        return this.with(relationshipName, new List<SObjectField>{ field1, field2 });
    }

    @NamespaceAccessible
    public Queryable with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
        return this.with(relationshipName, new List<SObjectField>{ field1, field2, field3 });
    }

    @NamespaceAccessible
    public Queryable with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return this.with(relationshipName, new List<SObjectField>{ field1, field2, field3, field4 });
    }

    @NamespaceAccessible
    public Queryable with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
        return this.with(relationshipName, new List<SObjectField>{ field1, field2, field3, field4, field5 });
    }

    @NamespaceAccessible
    public Queryable with(String relationshipName, Iterable<SObjectField> fields) {
        this.builder.fields.relationshipFields.add(relationshipName, fields);
        return this;
    }

    @NamespaceAccessible
    public Queryable with(SubQuery subQuery) {
        this.builder.subQueries.add(subQuery);
        return this;
    }

    @NamespaceAccessible
    public Queryable with(TypeOf typeOf) {
        this.builder.fields.typeOfFields.add(typeOf);
        return this;
    }

    @NamespaceAccessible
    public Queryable count() {
        this.builder.fields.count();
        return this;
    }

    @NamespaceAccessible
    public Queryable count(SObjectField field) {
        return this.count(field, '');
    }

    @NamespaceAccessible
    public Queryable count(SObjectField field, String alias) {
        return this.withAggregateFunction('COUNT', field, alias);
    }

    @NamespaceAccessible
    public Queryable count(String relationshipName, SObjectField field) {
        return this.count(relationshipName, field, '');
    }

    @NamespaceAccessible
    public Queryable count(String relationshipName, SObjectField field, String alias) {
        return this.withAggregateFunction('COUNT', relationshipName, field, alias);
    }

    @NamespaceAccessible
    public Queryable avg(SObjectField field) {
        return this.avg(field, '');
    }

    @NamespaceAccessible
    public Queryable avg(SObjectField field, String alias) {
        return this.withAggregateFunction('AVG', field, alias);
    }

    @NamespaceAccessible
    public Queryable avg(String relationshipName, SObjectField field) {
        return this.avg(relationshipName, field, '');
    }

    @NamespaceAccessible
    public Queryable avg(String relationshipName, SObjectField field, String alias) {
        return this.withAggregateFunction('AVG', relationshipName, field, alias);
    }

    @NamespaceAccessible
    public Queryable countDistinct(SObjectField field) {
        return this.countDistinct(field, '');
    }

    @NamespaceAccessible
    public Queryable countDistinct(SObjectField field, String alias) {
        return this.withAggregateFunction('COUNT_DISTINCT', field, alias);
    }

    @NamespaceAccessible
    public Queryable countDistinct(String relationshipName, SObjectField field) {
        return this.countDistinct(relationshipName, field, '');
    }

    @NamespaceAccessible
    public Queryable countDistinct(String relationshipName, SObjectField field, String alias) {
        return this.withAggregateFunction('COUNT_DISTINCT', relationshipName, field, alias);
    }

    @NamespaceAccessible
    public Queryable min(SObjectField field) {
        return this.min(field, '');
    }

    @NamespaceAccessible
    public Queryable min(SObjectField field, String alias) {
        return this.withAggregateFunction('MIN', field, alias);
    }

    @NamespaceAccessible
    public Queryable min(String relationshipName, SObjectField field) {
        return this.min(relationshipName, field, '');
    }

    @NamespaceAccessible
    public Queryable min(String relationshipName, SObjectField field, String alias) {
        return this.withAggregateFunction('MIN', relationshipName, field, alias);
    }

    @NamespaceAccessible
    public Queryable max(SObjectField field) {
        return this.max(field, '');
    }

    @NamespaceAccessible
    public Queryable max(SObjectField field, String alias) {
        return this.withAggregateFunction('MAX', field, alias);
    }

    @NamespaceAccessible
    public Queryable max(String relationshipName, SObjectField field) {
        return this.max(relationshipName, field, '');
    }

    @NamespaceAccessible
    public Queryable max(String relationshipName, SObjectField field, String alias) {
        return this.withAggregateFunction('MAX', relationshipName, field, alias);
    }

    @NamespaceAccessible
    public Queryable sum(SObjectField field) {
        return this.sum(field, '');
    }

    @NamespaceAccessible
    public Queryable sum(SObjectField field, String alias) {
        return this.withAggregateFunction('SUM', field, alias);
    }

    @NamespaceAccessible
    public Queryable sum(String relationshipName, SObjectField field) {
        return this.sum(relationshipName, field, '');
    }

    @NamespaceAccessible
    public Queryable sum(String relationshipName, SObjectField field, String alias) {
        return this.withAggregateFunction('SUM', relationshipName, field, alias);
    }

    @NamespaceAccessible
    public Queryable grouping(SObjectField field, String alias) {
        return this.withAggregateFunction('GROUPING', field, alias);
    }

    private Queryable withAggregateFunction(String function, SObjectField field, String alias) {
        this.builder.fields.aggregateFields.add(function, field, alias);
        return this;
    }

    private Queryable withAggregateFunction(String function, String relationship, SObjectField field, String alias) {
        this.builder.fields.aggregateFields.add(function, relationship, field, alias);
        return this;
    }

    @NamespaceAccessible
    public Queryable toLabel(SObjectField field) {
        return this.toLabel(field.toString());
    }

    @NamespaceAccessible
    public Queryable toLabel(SObjectField field, String alias) {
        return this.toLabel(field.toString(), alias);
    }

    @NamespaceAccessible
    public Queryable toLabel(String field) {
        return this.toLabel(field, '');
    }

    @NamespaceAccessible
    public Queryable toLabel(String field, String alias) {
        return this.withFunction('toLabel', field, alias);
    }

    @NamespaceAccessible
    public Queryable toLabel(Iterable<String> fields) {
        for (String field : fields) {
            this.toLabel(field);
        }
        return this;
    }

    @NamespaceAccessible
    public Queryable format(SObjectField field) {
        return this.format(field, '');
    }

    @NamespaceAccessible
    public Queryable format(SObjectField field, String alias) {
        return this.withFunction('FORMAT', field.toString(), alias);
    }

    private Queryable withFunction(String function, String field, String alias) {
        this.builder.fields.functionsFields.add(function, field, alias);
        return this;
    }

    @NamespaceAccessible
    public Queryable delegatedScope() {
        return this.scope('DELEGATED');
    }

    @NamespaceAccessible
    public Queryable mineScope() {
        return this.scope('MINE');
    }

    @NamespaceAccessible
    public Queryable mineAndMyGroupsScope() {
        return this.scope('MINE_AND_MY_GROUPS');
    }

    @NamespaceAccessible
    public Queryable myTerritoryScope() {
        return this.scope('MY_TERRITORY');
    }

    @NamespaceAccessible
    public Queryable myTeamTerritoryScope() {
        return this.scope('MY_TEAM_TERRITORY');
    }

    @NamespaceAccessible
    public Queryable teamScope() {
        return this.scope('TEAM');
    }

    private Queryable scope(String scope) {
        this.builder.scope.set(scope);
        return this;
    }

    @NamespaceAccessible
    public Queryable whereAre(FilterGroup filterGroup) {
        this.builder.conditions.add(filterGroup);
        return this;
    }

    @NamespaceAccessible
    public Queryable whereAre(Filter filter) {
        this.builder.conditions.add(filter);
        return this;
    }

    @NamespaceAccessible
    public Queryable whereAre(String conditions) {
        this.builder.conditions.add(conditions);
        return this;
    }

    @NamespaceAccessible
    public Queryable conditionLogic(String conditionLogic) {
        this.builder.conditions.conditionLogic(conditionLogic);
        return this;
    }

    @NamespaceAccessible
    public Queryable anyConditionMatching() {
        this.builder.conditions.anyConditionMatching();
        return this;
    }

    @NamespaceAccessible
    public Queryable groupBy(SObjectField field) {
        return this.groupBy(field.toString());
    }

    @NamespaceAccessible
    public Queryable groupBy(String field) {
        this.builder.fields.withGroupedField(field);
        this.builder.groupBy.with(field);
        return this;
    }

    @NamespaceAccessible
    public Queryable groupBy(String relationshipName, SObjectField field) {
        this.builder.fields.withGroupedField(relationshipName + '.' + field.toString());
        this.builder.groupBy.with(relationshipName, field);
        return this;
    }

    @NamespaceAccessible
    public Queryable groupByRollup(SObjectField field) {
        this.builder.fields.withGroupedField(field.toString());
        return this.groupBy(field, 'ROLLUP');
    }

    @NamespaceAccessible
    public Queryable groupByRollup(String relationshipName, SObjectField field) {
        this.builder.fields.withGroupedField(relationshipName + '.' + field.toString());
        return this.groupBy(relationshipName, field, 'ROLLUP');
    }

    @NamespaceAccessible
    public Queryable groupByCube(SObjectField field) {
        this.builder.fields.withGroupedField(field.toString());
        return this.groupBy(field, 'CUBE');
    }

    @NamespaceAccessible
    public Queryable groupByCube(String relationshipName, SObjectField field) {
        this.builder.fields.withGroupedField(relationshipName + '.' + field.toString());
        return this.groupBy(relationshipName, field, 'CUBE');
    }

    private Queryable groupBy(SObjectField field, String function) {
        this.builder.groupBy.with(field.toString(), function);
        this.builder.fields.withGroupedField(field.toString());
        return this;
    }

    private Queryable groupBy(String relationshipName, SObjectField field, String function) {
        this.builder.groupBy.with(relationshipName, field.toString(), function);
        this.builder.fields.withGroupedField(relationshipName + '.' + field.toString());
        return this;
    }

    @NamespaceAccessible
    public Queryable have(HavingFilterGroup havingFilterGroup) {
        this.builder.havingClause.add(havingFilterGroup);
        return this;
    }

    @NamespaceAccessible
    public Queryable have(HavingFilter havingFilter) {
        this.builder.havingClause.add(havingFilter);
        return this;
    }

    @NamespaceAccessible
    public Queryable have(String havingConditions) {
        this.builder.havingClause.add(havingConditions);
        return this;
    }

    @NamespaceAccessible
    public Queryable havingConditionLogic(String havingConditionsOrder) {
        this.builder.havingClause.conditionLogic(havingConditionsOrder);
        return this;
    }

    @NamespaceAccessible
    public Queryable anyHavingConditionMatching() {
        this.builder.havingClause.anyConditionMatching();
        return this;
    }

    @NamespaceAccessible
    public Queryable withDataCategory(DataCategoryFilter dataCategoryFilter) {
        this.builder.dataCategory.add(dataCategoryFilter);
        return this;
    }

    @NamespaceAccessible
    public Queryable orderBy(SObjectField field) {
        return this.orderBy(field.toString());
    }

    @NamespaceAccessible
    public Queryable orderBy(String field) {
        this.builder.orderBys.newOrderBy().with(field);
        return this;
    }

    @NamespaceAccessible
    public Queryable orderBy(String field, String direction) {
        this.builder.orderBys.newOrderBy().with(field);
        this.builder.orderBys.latestOrderBy().sortingOrder(direction);
        return this;
    }

    @NamespaceAccessible
    public Queryable orderBy(String relationshipName, SObjectField field) {
        return this.orderBy(relationshipName + '.' + field.toString());
    }

    @NamespaceAccessible
    public Queryable orderByCount(SObjectField field) {
        return this.orderBy('COUNT(' + field.toString() + ')');
    }

    @NamespaceAccessible
    public Queryable orderBy(Distance distance) {
        this.builder.orderBys.newOrderBy().with(distance);
        return this;
    }

    @NamespaceAccessible
    public Queryable sortDesc() {
        return this.sort('DESC');
    }

    @NamespaceAccessible
    public Queryable sort(String direction) {
        this.builder.latestOrderBy.sortingOrder(direction);
        return this;
    }

    @NamespaceAccessible
    public Queryable nullsLast() {
        return this.nullsOrder('LAST');
    }

    @NamespaceAccessible
    public Queryable nullsOrder(String nullsOrder) {
        this.builder.latestOrderBy.nullsOrder(nullsOrder);
        return this;
    }

    @NamespaceAccessible
    public Queryable setLimit(Integer amount) {
        this.builder.soqlLimit.set(amount);
        return this;
    }

    @NamespaceAccessible
    public Queryable offset(Integer startingRow) {
        this.builder.soqlOffset.set(startingRow);
        return this;
    }

    @NamespaceAccessible
    public Queryable forReference() {
        return this.setFor('FOR REFERENCE');
    }

    @NamespaceAccessible
    public Queryable forView() {
        return this.setFor('FOR VIEW');
    }

    @NamespaceAccessible
    public Queryable forUpdate() {
        return this.setFor('FOR UPDATE');
    }

    @NamespaceAccessible
    public Queryable allRows() {
        return this.setFor('ALL ROWS');
    }

    private Queryable setFor(String forStatement) {
        this.builder.soqlFor.set(forStatement);
        return this;
    }

    @NamespaceAccessible
    public Queryable userMode() {
        this.executor.accessMode(AccessLevel.USER_MODE);
        return this;
    }

    @NamespaceAccessible
    public Queryable systemMode() {
        this.executor.accessMode(AccessLevel.SYSTEM_MODE);
        return this;
    }

    @NamespaceAccessible
    public Queryable stripInaccessible() {
        return this.stripInaccessible(AccessType.READABLE);
    }

    @NamespaceAccessible
    public Queryable stripInaccessible(AccessType accessType) {
        this.executor.stripInaccessible(accessType);
        return this;
    }

    @NamespaceAccessible
    public Queryable withSharing() {
        this.executor.withSharing();
        return this;
    }

    @NamespaceAccessible
    public Queryable withoutSharing() {
        this.executor.withoutSharing();
        return this;
    }

    @NamespaceAccessible
    public Queryable mockId(String queryIdentifier) {
        this.executor.mock(rflib_SOQL.queryIdToMock.get(queryIdentifier));
        return this;
    }

    @NamespaceAccessible
    public Queryable preview() {
        System.debug(LoggingLevel.ERROR, '\n\n============ rflib_SOQL Preview ============\n' + this.toString() + '\n=======================================\n');
        System.debug(LoggingLevel.ERROR, '\n\n============ rflib_SOQL Binding ============\n' + JSON.serializePretty(this.binding()) + '\n=======================================\n');
        return this;
    }

    @NamespaceAccessible
    public Map<String, Object> binding() {
        return binder.getBindingMap();
    }

    @NamespaceAccessible
    public Id toId() {
        this.builder.fields.clearAllFields(); // other fields not needed
        return this.toObject()?.Id;
    }

    @NamespaceAccessible
    public Set<Id> toIds() {
        this.builder.fields.clearAllFields(); // other fields not needed
        return this.toMap().keySet();
    }

    @NamespaceAccessible
    public Set<Id> toIdsOf(SObjectField field) {
        return this.toIdsOf(field.toString());
    }

    @NamespaceAccessible
    public Set<Id> toIdsOf(String relationshipName, SObjectField field) {
        return this.toIdsOf(relationshipName + '.' + field.toString());
    }

    private Set<Id> toIdsOf(String fieldToExtract) {
        if (fieldToExtract == 'Id') {
            // Id can't be grouped and aggregated (COUNT(Id)) in the same query
            throw new QueryException('Id field cannot be used in toIdsOf(). Use toIds() instead.');
        }

        // https://salesforce.stackexchange.com/questions/393308/get-a-list-of-one-column-from-a-soql-result
        this.builder.fields.clearAllFields(); // other fields not needed
        this.with(fieldToExtract, 'Id');
        this.with('COUNT(Id)'); // one query row per group instead of one per record
        this.groupBy(fieldToExtract);
        this.builder.conditions.addMasterCondition(Filter.with(fieldToExtract).isNotNull());

        return new Map<Id, SObject>(this.toAggregated(fieldToExtract)).keySet();
    }

    @NamespaceAccessible
    public Boolean doExist() {
        this.builder.fields.clearAllFields(); // other fields not needed
        return this.setLimit(1).toList().size() > 0;
    }

    @NamespaceAccessible
    public override String toString() {
        binder.reset(); // clear binding before query build
        return this.builder.toString();
    }

    @NamespaceAccessible
    public Object toValueOf(SObjectField fieldToExtract) {
        this.builder.fields.clearAllFields(); // other fields not needed
        return this.with(fieldToExtract).toObject()?.get(fieldToExtract);
    }

    @NamespaceAccessible
    public Set<String> toValuesOf(SObjectField fieldToExtract) {
        return this.toValuesOf(fieldToExtract.toString());
    }

    @NamespaceAccessible
    public Set<String> toValuesOf(String relationshipName, SObjectField targetKeyField) {
        return this.toValuesOf(relationshipName + '.' + targetKeyField.toString());
    }

    private Set<String> toValuesOf(String fieldToExtract) {
        if (fieldToExtract == 'Id') {
            // Id can't be grouped and aggregated (COUNT(Id)) in the same query
            throw new QueryException('Id field cannot be used in toValuesOf(). Use toIds() instead.');
        }

        // https://salesforce.stackexchange.com/questions/393308/get-a-list-of-one-column-from-a-soql-result
        this.builder.fields.clearAllFields(); // other fields not needed
        this.with(fieldToExtract, 'Id');
        this.with('COUNT(Id)'); // one query row per group instead of one per record
        this.groupBy(fieldToExtract);
        this.builder.conditions.addMasterCondition(Filter.with(fieldToExtract).isNotNull());

        return new Map<String, SObject>(this.toAggregated(fieldToExtract)).keySet();
    }

    @NamespaceAccessible
    public Integer toInteger() {
        this.builder.fields.addCountWhenNotPresented();
        return this.executor.toInteger();
    }

    @NamespaceAccessible
    public SObject toObject() {
        return this.executor.toObject();
    }

    @NamespaceAccessible
    public List<SObject> toList() {
        return this.executor.toList();
    }

    @NamespaceAccessible
    public List<AggregateResult> toAggregated() {
        return this.toList();
    }

    private List<AggregateResult> toAggregated(String fieldToExtract) {
        return this.executor.toAggregated(fieldToExtract);
    }

    @NamespaceAccessible
    public List<AggregateResultProxy> toAggregatedProxy() {
        return this.executor.toAggregatedProxy();
    }

    @NamespaceAccessible
    public Map<Id, SObject> toMap() {
        return this.converter.transform(this.executor.toList()).toMap();
    }

    @NamespaceAccessible
    public Map<Id, SObject> toIdMapBy(SObjectField field) {
        this.with(field);
        this.whereAre(Filter.with(field).isNotNull());
        return this.converter.transform(this.executor.toList()).toIdMapBy(field);
    }

    @NamespaceAccessible
    public Map<Id, SObject> toIdMapBy(String relationshipName, SObjectField targetKeyField) {
        this.with(relationshipName + '.' + targetKeyField.toString());
        this.whereAre(Filter.with(relationshipName, targetKeyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toIdMapBy(relationshipName, targetKeyField);
    }

    @NamespaceAccessible
    public Map<Id, List<SObject>> toAggregatedIdMapBy(SObjectField keyField) {
        this.with(keyField);
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toAggregatedIdMapBy(keyField);
    }

    @NamespaceAccessible
    public Map<Id, List<SObject>> toAggregatedIdMapBy(String relationshipName, SObjectField targetKeyField) {
        this.with(relationshipName + '.' + targetKeyField.toString());
        this.whereAre(Filter.with(relationshipName, targetKeyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toAggregatedIdMapBy(relationshipName, targetKeyField);
    }

    @NamespaceAccessible
    public Map<String, SObject> toMap(SObjectField keyField) {
        this.with(keyField);
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toMap(keyField);
    }

    @NamespaceAccessible
    public Map<String, SObject> toMap(String relationshipName, SObjectField targetKeyField) {
        this.with(relationshipName + '.' + targetKeyField.toString());
        this.whereAre(Filter.with(relationshipName, targetKeyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toMap(relationshipName, targetKeyField);
    }

    @NamespaceAccessible
    public Map<String, String> toMap(SObjectField keyField, SObjectField valueField) {
        this.builder.fields.clearAllFields(); // other fields not needed
        this.with(keyField, valueField);
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toMap(keyField, valueField);
    }

    @NamespaceAccessible
    public Map<String, String> toMap(SObjectField keyField, String relationshipName, SObjectField targetKeyField) {
        this.builder.fields.clearAllFields(); // other fields not needed
        this.with(keyField);
        this.with(relationshipName + '.' + targetKeyField.toString());
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toMap(keyField, relationshipName, targetKeyField);
    }

    @NamespaceAccessible
    public Map<String, List<SObject>> toAggregatedMap(SObjectField keyField) {
        this.with(keyField);
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toAggregatedMap(keyField);
    }

    @NamespaceAccessible
    public Map<String, List<SObject>> toAggregatedMap(String relationshipName, SObjectField targetKeyField) {
        this.with(relationshipName + '.' + targetKeyField.toString());
        this.whereAre(Filter.with(relationshipName, targetKeyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toAggregatedMap(relationshipName, targetKeyField);
    }

    @NamespaceAccessible
    public Map<String, List<String>> toAggregatedMap(SObjectField keyField, SObjectField valueField) {
        this.builder.fields.clearAllFields(); // other fields not needed
        this.with(keyField, valueField);
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toAggregatedMap(keyField, valueField);
    }

    @NamespaceAccessible
    public Map<String, List<String>> toAggregatedMap(SObjectField keyField, String relationshipName, SObjectField targetKeyField) {
        this.builder.fields.clearAllFields(); // other fields not needed
        this.with(keyField);
        this.with(relationshipName + '.' + targetKeyField.toString());
        this.whereAre(Filter.with(keyField).isNotNull());
        return this.converter.transform(this.executor.toList()).toAggregatedMap(keyField, relationshipName, targetKeyField);
    }

    @NamespaceAccessible
    public Database.QueryLocator toQueryLocator() {
        return this.executor.toQueryLocator();
    }

    @NamespaceAccessible
    public Database.Cursor toCursor() {
        return this.executor.toCursor();
    }

    @NamespaceAccessible
    public Database.PaginationCursor toPaginationCursor() {
        return this.executor.toPaginationCursor();
    }

    @NamespaceAccessible
    public Queryable byId(SObject record) {
        return this.byId(record.Id);
    }

    @NamespaceAccessible
    public Queryable byId(Id recordId) {
        return this.whereAre(Filter.id().equal(recordId));
    }

    @NamespaceAccessible
    public Queryable byIds(Iterable<Id> recordIds) {
        return this.whereAre(Filter.id().isIn(recordIds));
    }

    @NamespaceAccessible
    public Queryable byIds(List<SObject> records) {
        return this.whereAre(Filter.id().isIn(records));
    }

    @NamespaceAccessible
    public Queryable byRecordType(String recordTypeDeveloperName) {
        return this.whereAre(Filter.recordType().equal(recordTypeDeveloperName));
    }

    private interface QueryClause {
        String toString();
    }

    private class Builder implements QueryClause {
        private List<QueryClause> clauses = new QueryClause[12];

        public Builder(String ofObject) {
            this.clauses.set(0, new SoqlFields(ofObject));
            this.clauses.set(2, new SoqlFrom(ofObject));
        }

        public SoqlFields fields {
            get {
                return (SoqlFields) this.clauses[0];
            }
        }

        public SoqlSubQueries subQueries {
            get {
                return (SoqlSubQueries) getQueryClause(1, SoqlSubQueries.class);
            }
        }

        public SoqlScope scope {
            get {
                return (SoqlScope) getQueryClause(3, SoqlScope.class);
            }
        }

        public MainFilterGroup conditions {
            get {
                return (MainFilterGroup) getQueryClause(4, MainFilterGroup.class);
            }
        }

        public MainDataCategoryGroup dataCategory {
            get {
                return (MainDataCategoryGroup) getQueryClause(5, MainDataCategoryGroup.class);
            }
        }

        public SoqlGroupBy groupBy {
            get {
                return (SoqlGroupBy) getQueryClause(6, SoqlGroupBy.class);
            }
        }

        public MainHavingGroup havingClause {
            get {
                return (MainHavingGroup) getQueryClause(7, MainHavingGroup.class);
            }
        }

        public SoqlOrderBy latestOrderBy {
            get {
                return this.orderBys.latestOrderBy();
            }
        }

        public SoqlOrderBys orderBys {
            get {
                return (SoqlOrderBys) getQueryClause(8, SoqlOrderBys.class);
            }
        }

        public SoqlLimit soqlLimit {
            get {
                return (SoqlLimit) getQueryClause(9, SoqlLimit.class);
            }
        }

        public SoqlOffset soqlOffset {
            get {
                return (SoqlOffset) getQueryClause(10, SoqlOffset.class);
            }
        }

        public SoqlFor soqlFor {
            get {
                return (SoqlFor) getQueryClause(11, SoqlFor.class);
            }
        }

        private QueryClause getQueryClause(Integer position, System.Type queryClause) {
            if (this.clauses[position] == null) {
                this.clauses.set(position, (QueryClause) queryClause.newInstance());
            }
            return this.clauses[position];
        }

        public override String toString() {
            List<String> queryParts = new List<String>();

            for (QueryClause clause : this.clauses) {
                if (clause != null) {
                    queryParts.add(clause.toString());
                }
            }

            return String.join(queryParts, ' ').trim();
        }
    }

    private class SoqlFields implements QueryClause {
        public PlainFields plainFields = new PlainFields();
        public RelationshipFields relationshipFields = new RelationshipFields();
        public FunctionsFields functionsFields = new FunctionsFields(); // toLabel, FORMAT
        public AggregateFunctionsFields aggregateFields = new AggregateFunctionsFields();
        public TypeOfFields typeOfFields = new TypeOfFields();

        private String ofObject;
        private Set<String> groupedFields = new Set<String>();

        public SoqlFields(String ofObject) {
            this.ofObject = ofObject;
        }

        public void count() {
            this.clearAllFields(); // COUNT() must be the only element in the SELECT list.
            this.aggregateFields.add('COUNT()', '');
        }

        public void with(String commaSeparatedFields) {
            // Add to Set to avoid "duplicate field selected" error
            for (String splitField : commaSeparatedFields.split(',')) {
                this.classifyField(splitField);
            }
        }

        private void classifyField(String field) {
            String trimmedField = field.trim();

            if (this.functionsFields.isQualified(trimmedField)) {
                this.functionsFields.add(trimmedField);
            } else if (this.aggregateFields.isQualified(trimmedField)) {
                this.aggregateFields.add(trimmedField);
            } else if (this.relationshipFields.isQualified(trimmedField)) {
                this.relationshipFields.add(trimmedField);
            } else {
                this.plainFields.add(trimmedField);
            }
        }

        public void withGroupedField(String field) {
            this.groupedFields.add(field);
        }

        public void withFieldSet(String fieldSetName) {
            FieldSet fieldSet = Schema.describeSObjects(new List<String>{ this.ofObject }, SObjectDescribeOptions.DEFERRED)[0].fieldSets.getMap().get(fieldSetName);

            if (fieldSet == null) {
                throw new QueryException('FieldSet with name ' + fieldSetName + ' does not exist!');
            }

            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                String currentField = field.getFieldPath();

                if (this.relationshipFields.isQualified(currentField)) {
                    this.relationshipFields.add(currentField);
                } else {
                    this.plainFields.add(currentField);
                }
            }
        }

        public void clearAllFields() {
            this.plainFields.clear();
            this.relationshipFields.clear();
            this.aggregateFields.clear();
            this.functionsFields.clear();
            this.typeOfFields.clear();
        }

        public void addCountWhenNotPresented() {
            if (this.aggregateFields.isEmpty()) {
                this.count();
            }
        }

        public override String toString() {
            if (
                this.plainFields.isEmpty() &&
                this.relationshipFields.isEmpty() &&
                this.aggregateFields.isEmpty() &&
                this.functionsFields.isEmpty() &&
                this.typeOfFields.isEmpty()
            ) {
                this.plainFields.add('Id');
            }

            if (!this.groupedFields.isEmpty() || !this.aggregateFields.isEmpty()) {
                // To avoid "Field must be grouped or aggregated" error retain only grouped or aggregated fields
                this.plainFields.retainAll(groupedFields);
                this.relationshipFields.retainAll(groupedFields);
                this.functionsFields.retainAll(groupedFields);
                this.typeOfFields.retainAll(groupedFields);
            }

            List<String> selectFields = new List<String>();

            selectFields.addAll(this.plainFields.get());
            selectFields.addAll(this.relationshipFields.get());
            selectFields.addAll(this.functionsFields.get());
            selectFields.addAll(this.aggregateFields.get());
            selectFields.addAll(this.typeOfFields.get());

            return 'SELECT ' + String.join(selectFields, ', ');
        }
    }

    private abstract class SelectFields {
        protected Set<String> fields = new Set<String>();

        public void add(String field) {
            this.fields.add(field);
        }

        public Boolean isEmpty() {
            return this.fields.isEmpty();
        }

        public void clear() {
            this.fields.clear();
        }

        public Set<String> get() {
            return this.fields;
        }

        public void retainAll(Set<String> fieldsToRetain) {
            this.fields.retainAll(fieldsToRetain);
        }
    }

    private class PlainFields extends SelectFields {
        public void add(Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                this.add(field.toString());
            }
        }
    }

    private class RelationshipFields extends SelectFields {
        public void add(String relationshipPath, Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                this.add(relationshipPath, field);
            }
        }

        public void add(String relationshipPath, SObjectField field) {
            this.add(relationshipPath + '.' + field.toString());
        }

        public Boolean isQualified(String field) {
            return !field.contains('(') && !field.contains(')') && field.contains('.');
        }
    }

    private class AggregateFunctionsFields extends SelectFields {
        private final Set<String> AGGREGATE_FUNCTIONS = new Set<String>{ 'COUNT', 'AVG', 'COUNT_DISTINCT', 'MIN', 'MAX', 'SUM' };
        private final Set<String> DATE_FUNCTIONS = new Set<String>{
            'CALENDAR_MONTH',
            'CALENDAR_QUARTER',
            'CALENDAR_YEAR',
            'DAY_IN_MONTH',
            'DAY_IN_WEEK',
            'DAY_IN_YEAR',
            'DAY_ONLY',
            'FISCAL_MONTH',
            'FISCAL_QUARTER',
            'FISCAL_YEAR',
            'HOUR_IN_DAY',
            'WEEK_IN_MONTH',
            'WEEK_IN_YEAR'
        };

        public void add(String function, SObjectField field, String alias) {
            this.add(function + '(' + field.toString() + ')', alias);
        }

        public void add(String function, String relationship, SObjectField field, String alias) {
            this.add(function + '(' + relationship + '.' + field.toString() + ')', alias);
        }

        private void add(String aggregateFunction, String alias) {
            if (String.isNotBlank(alias)) {
                aggregateFunction += ' ' + alias;
            }
            this.add(aggregateFunction);
        }

        private Boolean isQualified(String field) {
            Boolean isFieldAliasing = !field.contains('(') && !field.contains(')') && field.contains(' ');
            String functionName = field.split('\\(')[0].toUpperCase();
            return AGGREGATE_FUNCTIONS.contains(functionName) || DATE_FUNCTIONS.contains(functionName) || isFieldAliasing;
        }
    }

    private class FunctionsFields extends SelectFields {
        private final Set<String> FUNCTIONS = new Set<String>{ 'CONVERTCURRENCY', 'CONVERTTIMEZONE', 'FORMAT', 'GROUPING', 'TOLABEL' };

        public void add(String function, String field, String alias) {
            this.add(function + '(' + field + ')', alias);
        }

        public void add(String function, String alias) {
            if (String.isNotBlank(alias)) {
                function += ' ' + alias;
            }
            this.add(function);
        }

        public Boolean isQualified(String field) {
            String functionName = field.split('\\(')[0].toUpperCase();
            return FUNCTIONS.contains(functionName);
        }
    }

    private class TypeOfFields extends SelectFields {
        public void add(TypeOf typeOf) {
            String typeOfExpression = typeOf.toString();

            if (String.isNotEmpty(typeOfExpression)) {
                this.add(typeOfExpression);
            }
        }
    }

    private class TypeOfWhenThen {
        public PlainFields plainFields = new PlainFields();
        public RelationshipFields relationshipFields = new RelationshipFields();

        private String prefix;

        public TypeOfWhenThen(SObjectType whenObject) {
            this.prefix = 'WHEN ' + whenObject.toString() + ' THEN ';
        }

        public TypeOfWhenThen() {
            this.prefix = 'ELSE ';
        }

        public Boolean isEmpty() {
            return this.plainFields.isEmpty() && this.relationshipFields.isEmpty();
        }

        public void with(String commaSeparatedFields) {
            // Add to Set to avoid "duplicate field selected" error
            for (String splitField : commaSeparatedFields.split(',')) {
                this.classifyField(splitField);
            }
        }

        private void classifyField(String field) {
            String trimmedField = field.trim();

            if (this.relationshipFields.isQualified(trimmedField)) {
                this.relationshipFields.add(trimmedField);
            } else {
                this.plainFields.add(trimmedField);
            }
        }

        public override String toString() {
            List<String> fields = new List<String>();

            fields.addAll(this.plainFields.get());
            fields.addAll(this.relationshipFields.get());

            return this.prefix + String.join(fields, ', ');
        }
    }

    private class SoqlSubQuery implements SubQuery {
        private Builder builder;
        private String childRelationshipName;

        public SubQuery of(String ofObject) {
            this.builder = new Builder(ofObject);
            this.childRelationshipName = ofObject;
            return this;
        }

        public SubQuery with(SObjectField field) {
            this.builder.fields.plainFields.add(field.toString());
            return this;
        }

        public SubQuery with(SObjectField field1, SObjectField field2) {
            return this.with(field1).with(field2);
        }

        public SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3) {
            return this.with(field1).with(field2).with(field3);
        }

        public SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            return this.with(field1).with(field2).with(field3).with(field4);
        }

        public SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            return this.with(field1).with(field2).with(field3).with(field4).with(field5);
        }

        public SubQuery with(Iterable<SObjectField> fields) {
            this.builder.fields.plainFields.add(fields);
            return this;
        }

        public SubQuery with(String fields) {
            this.builder.fields.with(fields);
            return this;
        }

        public SubQuery with(String relationshipName, SObjectField field) {
            this.builder.fields.relationshipFields.add(relationshipName, new List<SObjectField>{ field });
            return this;
        }

        public SubQuery with(String relationshipName, SObjectField field1, SObjectField field2) {
            this.builder.fields.relationshipFields.add(relationshipName, new List<SObjectField>{ field1, field2 });
            return this;
        }

        public SubQuery with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
            this.builder.fields.relationshipFields.add(relationshipName, new List<SObjectField>{ field1, field2, field3 });
            return this;
        }

        public SubQuery with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.builder.fields.relationshipFields.add(relationshipName, new List<SObjectField>{ field1, field2, field3, field4 });
            return this;
        }

        public SubQuery with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.builder.fields.relationshipFields.add(relationshipName, new List<SObjectField>{ field1, field2, field3, field4, field5 });
            return this;
        }

        public SubQuery with(String relationshipName, Iterable<SObjectField> fields) {
            this.builder.fields.relationshipFields.add(relationshipName, fields);
            return this;
        }

        public SubQuery with(SubQuery subQuery) {
            this.builder.subQueries.add(subQuery);
            return this;
        }

        public SubQuery toLabel(SObjectField field) {
            return this.toLabel(field.toString());
        }

        public SubQuery toLabel(SObjectField field, String alias) {
            return this.toLabel(field.toString(), alias);
        }

        public SubQuery toLabel(String field) {
            return this.toLabel(field, '');
        }

        public SubQuery toLabel(String field, String alias) {
            return this.withFunction('toLabel', field, alias);
        }

        public SubQuery toLabel(Iterable<String> fields) {
            for (String field : fields) {
                this.toLabel(field);
            }
            return this;
        }

        private SubQuery withFunction(String function, String field, String alias) {
            this.builder.fields.functionsFields.add(function, field, alias);
            return this;
        }

        public SubQuery whereAre(FilterGroup filterGroup) {
            this.builder.conditions.add(filterGroup);
            return this;
        }

        public SubQuery whereAre(Filter filter) {
            this.builder.conditions.add(filter);
            return this;
        }

        public SubQuery orderBy(SObjectField field) {
            this.builder.orderBys.newOrderBy().with(field.toString());
            return this;
        }

        public SubQuery orderBy(String field) {
            this.builder.orderBys.newOrderBy().with(field);
            return this;
        }

        public SubQuery orderBy(String relationshipName, SObjectField field) {
            this.builder.orderBys.newOrderBy().with(relationshipName + '.' + field.toString());
            return this;
        }

        public SubQuery orderBy(Distance distance) {
            this.builder.orderBys.newOrderBy().with(distance);
            return this;
        }

        public SubQuery sortDesc() {
            this.builder.latestOrderBy.sortingOrder('DESC');
            return this;
        }

        public SubQuery sort(String direction) {
            this.builder.latestOrderBy.sortingOrder(direction);
            return this;
        }

        public SubQuery nullsLast() {
            this.builder.latestOrderBy.nullsOrder('LAST');
            return this;
        }

        public SubQuery setLimit(Integer amount) {
            this.builder.soqlLimit.set(amount);
            return this;
        }

        public SubQuery offset(Integer startingRow) {
            this.builder.soqlOffset.set(startingRow);
            return this;
        }

        public SubQuery forReference() {
            this.builder.soqlFor.set('FOR REFERENCE');
            return this;
        }

        public SubQuery forView() {
            this.builder.soqlFor.set('FOR VIEW');
            return this;
        }

        public override String toString() {
            return this.builder.toString();
        }

        public String getChildRelationshipName() {
            return this.childRelationshipName;
        }
    }

    private class SoqlTypeOf implements TypeOf {
        private String ofField;
        private Set<SObjectType> whenObjects = new Set<SObjectType>();
        private List<TypeOfWhenThen> whenThens = new List<TypeOfWhenThen>();
        private TypeOfWhenThen elseFields = new TypeOfWhenThen();

        public TypeOf of(String ofField) {
            if (this.ofField != null) {
                throw new QueryException('TYPEOF has already been initialized for: ' + this.ofField);
            }

            this.ofField = ofField;
            return this;
        }

        public TypeOf of(SObjectField ofField) {
            return this.of(ofField.getDescribe().getRelationshipName());
        }

        public TypeOf when(SObjectType whenObject) {
            if (this.whenObjects.contains(whenObject)) {
                throw new QueryException('TYPEOF already contains configuration for: ' + whenObject.toString());
            }

            this.whenObjects.add(whenObject);
            this.whenThens.add(new TypeOfWhenThen(whenObject));
            return this;
        }

        public TypeOf then(SObjectField field) {
            this.latestWhenThen().plainFields.add(field.toString());
            return this;
        }

        public TypeOf then(SObjectField field1, SObjectField field2) {
            return this.then(field1).then(field2);
        }

        public TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3) {
            return this.then(field1, field2).then(field3);
        }

        public TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            return this.then(field1, field2, field3).then(field4);
        }

        public TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            return this.then(field1, field2, field3, field4).then(field5);
        }

        public TypeOf then(List<SObjectField> fields) {
            this.latestWhenThen().plainFields.add(fields);
            return this;
        }

        public TypeOf then(Iterable<String> fields) {
            if (!fields.iterator().hasNext()) {
                return this;
            }

            return this.then(String.join(fields, ','));
        }

        public TypeOf then(String fields) {
            this.latestWhenThen().with(fields);
            return this;
        }

        public TypeOf then(String relationshipName, SObjectField field) {
            return this.then(relationshipName, new List<SObjectField>{ field });
        }

        public TypeOf then(String relationshipName, SObjectField field1, SObjectField field2) {
            return this.then(relationshipName, new List<SObjectField>{ field1, field2 });
        }

        public TypeOf then(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
            return this.then(relationshipName, new List<SObjectField>{ field1, field2, field3 });
        }

        public TypeOf then(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            return this.then(relationshipName, new List<SObjectField>{ field1, field2, field3, field4 });
        }

        public TypeOf then(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            return this.then(relationshipName, new List<SObjectField>{ field1, field2, field3, field4, field5 });
        }

        public TypeOf then(String relationshipName, Iterable<SObjectField> fields) {
            this.latestWhenThen().relationshipFields.add(relationshipName, fields);
            return this;
        }

        public TypeOf whenElse(Iterable<String> fields) {
            if (!fields.iterator().hasNext()) {
                return this;
            }

            return this.whenElse(String.join(fields, ','));
        }

        public TypeOf whenElse(String fields) {
            this.elseFields.with(fields);
            return this;
        }

        public override String toString() {
            List<String> clauses = new List<String>();

            for (TypeOfWhenThen whenThen : this.whenThens) {
                if (!whenThen.isEmpty()) {
                    clauses.add(whenThen.toString());
                }
            }

            if (clauses.isEmpty()) {
                return '';
            }

            if (!this.elseFields.isEmpty()) {
                clauses.add(this.elseFields.toString());
            }

            return 'TYPEOF ' + this.ofField + ' ' + String.join(clauses, ' ') + ' END';
        }

        private TypeOfWhenThen latestWhenThen() {
            return this.whenThens.get(this.whenThens.size() - 1);
        }
    }

    private class SoqlSubQueries implements QueryClause {
        private List<SubQuery> subQueries = new List<SubQuery>();

        public void add(SubQuery subQuery) {
            this.subQueries.add(subQuery);
        }

        public override String toString() {
            List<String> subQueriesStrings = new List<String>();

            for (SubQuery sub : this.subQueries) {
                subQueriesStrings.add('(' + sub + ')');
            }

            return ', ' + String.join(subQueriesStrings, ', ');
        }

        public Set<String> get() {
            Set<String> subQueriesRelationshipNames = new Set<String>();

            for (SubQuery subQuery : this.subQueries) {
                subQueriesRelationshipNames.add(subQuery.getChildRelationshipName());
            }

            return subQueriesRelationshipNames;
        }
    }

    private class SoqlFrom implements QueryClause {
        private String objectApiName;

        public SoqlFrom(String objectType) {
            this.objectApiName = objectType;
        }

        public override String toString() {
            return 'FROM ' + this.objectApiName;
        }
    }

    private class SoqlScope implements QueryClause {
        private String scope = 'EVERYTHING';

        public void set(String scope) {
            this.scope = scope;
        }

        public override String toString() {
            return 'USING SCOPE ' + this.scope;
        }
    }

    private interface FilterClause {
        String toString();
        Boolean hasValue();
    }

    private virtual class FilterBuilder {
        protected List<FilterClause> conditions = new List<FilterClause>();
        protected String customOrder;
        protected String connector = 'AND';

        protected void add(FilterClause condition) {
            if (condition.hasValue()) {
                this.conditions.add(condition);
            }
        }

        protected String buildNested() {
            return String.format(this.getOrderWithSpecialCharacters(), this.conditions);
        }

        private String getOrderWithSpecialCharacters() {
            String orderWithSpecialCharacters = this.customOrder ?? this.getDefaultOrder();

            for (Integer i = 0; i < this.conditions.size(); i++) {
                orderWithSpecialCharacters = orderWithSpecialCharacters.replaceAll('\\b' + (i + 1).toString() + '\\b', '{' + i + '}');
            }

            return orderWithSpecialCharacters; // e.g ({0} AND ({1} AND {2}))
        }

        private String getDefaultOrder() {
            List<String> defaultOrder = new List<String>();

            for (Integer i = 0; i < this.conditions.size(); i++) {
                defaultOrder.add((i + 1).toString());
            }

            return String.join(defaultOrder, ' ' + this.connector + ' '); // e.g (0 AND 1 AND 2)
        }
    }

    private virtual class SoqlFilterGroup extends FilterBuilder implements FilterGroup {
        public FilterGroup add(FilterGroup filterGroup) {
            this.add(new FilterGroupAdapter(filterGroup));
            return this;
        }

        public FilterGroup add(Filter filter) {
            this.add(new FilterAdapter(filter));
            return this;
        }

        public FilterGroup add(String dynamicCondition) {
            this.add(new StringConditionAdapter(dynamicCondition));
            return this;
        }

        public FilterGroup add(List<Filter> filters) {
            for (Filter filter : filters) {
                this.add(filter);
            }
            return this;
        }

        public FilterGroup add(List<String> dynamicConditions) {
            for (String dynamicCondition : dynamicConditions) {
                this.add(dynamicCondition);
            }
            return this;
        }

        public FilterGroup anyConditionMatching() {
            this.connector = 'OR';
            return this;
        }

        public FilterGroup conditionLogic(String order) {
            this.customOrder = order;
            return this;
        }

        public FilterGroup ignoreWhen(Boolean logicExpression) {
            if (logicExpression) {
                this.conditions = new List<FilterClause>();
            }
            return this;
        }

        public Boolean hasValues() {
            return !this.conditions.isEmpty();
        }

        public virtual override String toString() {
            return '(' + this.buildNested() + ')';
        }
    }

    private class MainFilterGroup extends SoqlFilterGroup implements QueryClause {
        private Filter masterCondition;

        public void addMasterCondition(Filter filter) {
            this.masterCondition = filter;
        }

        public override String toString() {
            if (!this.hasValues() && this.masterCondition == null) {
                return '';
            }

            if (this.masterCondition != null) {
                if (this.hasValues()) {
                    return 'WHERE ' + this.masterCondition.toString() + ' AND (' + this.buildNested() + ')';
                }

                return 'WHERE ' + this.masterCondition.toString();
            }

            return 'WHERE ' + this.buildNested();
        }
    }

    private class FilterGroupAdapter implements FilterClause {
        private FilterGroup filterGroup;

        public FilterGroupAdapter(FilterGroup filterGroup) {
            this.filterGroup = filterGroup;
        }

        public Boolean hasValue() {
            return this.filterGroup.hasValues();
        }

        public override String toString() {
            return this.filterGroup.toString();
        }
    }

    private class FilterAdapter implements FilterClause {
        private Filter filter;

        public FilterAdapter(Filter filter) {
            this.filter = filter;
        }

        public Boolean hasValue() {
            return this.filter.hasValue();
        }

        public override String toString() {
            return this.filter.toString();
        }
    }

    private class StringConditionAdapter implements FilterClause {
        private String conditionString;

        public StringConditionAdapter(String dynamicCondition) {
            this.conditionString = dynamicCondition;
        }

        public Boolean hasValue() {
            return String.isNotEmpty(this.conditionString);
        }

        public override String toString() {
            return this.conditionString;
        }
    }

    private class SoqlFilter implements Filter {
        private String field;
        private String comparator;
        private Object value;
        private String wrapper = '{0}';
        private Boolean skipBinding = false;

        public Filter id() {
            return this.with('Id');
        }

        public Filter recordType() {
            return this.with('RecordType.DeveloperName');
        }

        public Filter name() {
            return this.with('Name');
        }

        public Filter with(SObjectField field) {
            return this.with(field.toString());
        }

        public Filter with(String relationshipName, SObjectField field) {
            return this.with(relationshipName + '.' + field.toString());
        }

        public Filter with(String field) {
            this.field = field;
            return this;
        }

        public Filter with(Distance distance) {
            this.field = distance.toString();
            return this;
        }

        public Filter isNull() {
            return this.equal(null);
        }

        public Filter isNotNull() {
            return this.notEqual(null);
        }

        public Filter isTrue() {
            return this.equal(true);
        }

        public Filter isFalse() {
            return this.equal(false);
        }

        public Filter equal(Object value) {
            return this.set('=', value);
        }

        public Filter notEqual(Object value) {
            return this.set('!=', value);
        }

        public Filter lessThan(Object value) {
            return this.set('<', value);
        }

        public Filter greaterThan(Object value) {
            return this.set('>', value);
        }

        public Filter lessOrEqual(Object value) {
            return this.set('<=', value);
        }

        public Filter greaterOrEqual(Object value) {
            return this.set('>=', value);
        }

        public Filter containsSome(Iterable<String> values) {
            return this.set('LIKE', values);
        }

        public Filter contains(String value) {
            return this.contains('%', formattedString(value), '%');
        }

        public Filter notContains(String value) {
            return this.notLike().contains(value);
        }

        public Filter endsWith(String value) {
            return this.contains('%', formattedString(value), '');
        }

        public Filter notEndsWith(String value) {
            return this.notLike().endsWith(value);
        }

        public Filter startsWith(String value) {
            return this.contains('', formattedString(value), '%');
        }

        public Filter notStartsWith(String value) {
            return this.notLike().startsWith(value);
        }

        public Filter contains(String prefix, String value, String suffix) {
            return this.set('LIKE', prefix + formattedString(value) + suffix);
        }

        public Filter notContains(String prefix, String value, String suffix) {
            return this.notLike().contains(prefix, value, suffix);
        }

        private String formattedString(String value) {
            return value ?? value?.trim();
        }

        public Filter isIn(Iterable<Object> iterable) {
            return this.set('IN', iterable);
        }

        public Filter isIn(InnerJoin joinQuery) {
            this.skipBinding = true;
            return this.set('IN', joinQuery);
        }

        public Filter isIn(Iterable<SObject> sourceRecords, SObjectField sourceKeyField) {
            return this.isIn(this.extractValues(sourceRecords, sourceKeyField));
        }

        private Filter notLike() {
            this.wrapper = '(NOT {0})';
            return this;
        }

        public Filter notIn(Iterable<Object> iterable) {
            return this.set('NOT IN', iterable);
        }

        public Filter notIn(InnerJoin joinQuery) {
            this.skipBinding = true;
            return this.set('NOT IN', joinQuery);
        }

        public Filter notIn(Iterable<SObject> sourceRecords, SObjectField sourceKeyField) {
            return this.notIn(this.extractValues(sourceRecords, sourceKeyField));
        }

        private List<Object> extractValues(Iterable<SObject> sourceRecords, SObjectField sourceKeyField) {
            // the list is typed after the field, so binding works for non-string columns (e.g. Date, Number)
            List<Object> values = (List<Object>) Type.forName('List<' + sourceKeyField.getDescribe().getSoapType() + '>').newInstance();

            for (SObject sourceRecord : sourceRecords) {
                Object value = sourceRecord?.get(sourceKeyField);

                if (value == null) {
                    continue;
                }

                values.add(value);
            }

            return values;
        }

        public Filter includesAll(Iterable<String> iterable) {
            return this.setMultipicklistFilter('INCLUDES', iterable, ';');
        }

        public Filter includesSome(Iterable<String> iterable) {
            return this.setMultipicklistFilter('INCLUDES', iterable, '\', \'');
        }

        public Filter excludesAll(Iterable<String> iterable) {
            return this.setMultipicklistFilter('EXCLUDES', iterable, '\', \'');
        }

        public Filter excludesSome(Iterable<String> iterable) {
            return this.setMultipicklistFilter('EXCLUDES', iterable, ';');
        }

        public Filter setMultipicklistFilter(String operator, Iterable<String> iterable, String separator) {
            // Bind expressions can't be used with other clauses, such as INCLUDES, EXCLUDES
            this.skipBinding = true;
            return this.set(operator, '(\'' + String.join(iterable, separator) + '\')');
        }

        private Filter set(String comparator, Object value) {
            this.value = value;
            this.comparator = comparator;
            return this;
        }

        public Boolean hasValue() {
            return String.isNotEmpty(this.field);
        }

        public Filter ignoreWhen(Boolean logicExpression) {
            if (logicExpression) {
                // Set field as empty to meet hasValue and ignore condition
                this.with('');
            }
            return this;
        }

        public Filter asDateLiteral() {
            // Date Literals can't be bound
            this.skipBinding = true;
            return this;
        }

        public override String toString() {
            return String.format(this.wrapper, new List<String>{ this.field + ' ' + this.comparator + (this.skipBinding ? ' ' + this.value : ' :' + binder.bind(this.value)) });
        }
    }

    private virtual class MainDataCategoryGroup extends FilterBuilder implements DataCategoryFilterGroup, QueryClause {
        public DataCategoryFilterGroup add(DataCategoryFilter dataCategoryFilter) {
            this.add(new DataCategoryFilterAdapter(dataCategoryFilter));
            return this;
        }

        public override String toString() {
            return 'WITH DATA CATEGORY ' + this.buildNested();
        }
    }

    private class DataCategoryFilterAdapter implements FilterClause {
        private DataCategoryFilter dataCategoryFilter;

        public DataCategoryFilterAdapter(DataCategoryFilter dataCategoryFilter) {
            this.dataCategoryFilter = dataCategoryFilter;
        }

        public Boolean hasValue() {
            return this.dataCategoryFilter.hasValue();
        }

        public override String toString() {
            return this.dataCategoryFilter.toString();
        }
    }

    private class SoqlDataCategoryFilter implements DataCategoryFilter {
        private String field;
        private String comparator;
        private String value;

        public DataCategoryFilter with(String field) {
            this.field = field;
            return this;
        }

        public DataCategoryFilter at(String category) {
            return this.set('AT', category);
        }

        public DataCategoryFilter at(Iterable<String> categories) {
            return this.set('AT', categories);
        }

        public DataCategoryFilter above(String category) {
            return this.set('ABOVE', category);
        }

        public DataCategoryFilter above(Iterable<String> categories) {
            return this.set('ABOVE', categories);
        }

        public DataCategoryFilter below(String category) {
            return this.set('BELOW', category);
        }

        public DataCategoryFilter below(Iterable<String> categories) {
            return this.set('BELOW', categories);
        }

        public DataCategoryFilter aboveOrBelow(String category) {
            return this.set('ABOVE_OR_BELOW', category);
        }

        public DataCategoryFilter aboveOrBelow(Iterable<String> categories) {
            return this.set('ABOVE_OR_BELOW', categories);
        }

        public DataCategoryFilter set(String operator, Iterable<String> iterable) {
            this.comparator = operator;
            this.value = '(' + String.join(iterable, ', ') + ')';
            return this;
        }

        private DataCategoryFilter set(String comparator, String value) {
            this.comparator = comparator;
            this.value = value;
            return this;
        }

        public Boolean hasValue() {
            return String.isNotEmpty(this.field);
        }

        public override String toString() {
            return this.field + ' ' + this.comparator + ' ' + this.value;
        }
    }

    private class SoqlJoinQuery implements InnerJoin {
        private Builder builder;

        public InnerJoin of(SObjectType ofObject) {
            this.builder = new Builder(ofObject.toString());
            return this;
        }

        public InnerJoin with(SObjectField field) {
            this.builder.fields.plainFields.add(field.toString());
            return this;
        }

        public InnerJoin whereAre(FilterGroup filterGroup) {
            this.builder.conditions.add(filterGroup);
            return this;
        }

        public InnerJoin whereAre(Filter filter) {
            this.builder.conditions.add(filter);
            return this;
        }

        public override String toString() {
            return '(' + this.builder.toString() + ')';
        }
    }

    private class SoqlGroupBy implements QueryClause {
        private Set<String> groupByFields = new Set<String>();
        private String groupByFunction = '';

        public void with(String relationshipName, SObjectField field) {
            this.with(relationshipName + '.' + field.toString());
        }

        private void with(String field) {
            this.setGroupByFunction('{0}');
            this.groupByFields.add(field.trim());
        }

        public void with(String field, String function) {
            this.setGroupByFunction(function + '({0})');
            this.groupByFields.add(field.trim());
        }

        public void with(String relationshipName, String field, String function) {
            this.setGroupByFunction(function + '({0})');
            this.groupByFields.add((relationshipName + '.' + field).trim());
        }

        public void setGroupByFunction(String newGroupByFunction) {
            if (String.isNotEmpty(groupByFunction) && groupByFunction != newGroupByFunction) {
                throw new QueryException('You can\'t use GROUP BY, GROUP BY ROLLUP and GROUP BY CUBE in the same query.');
            }
            this.groupByFunction = newGroupByFunction;
        }

        public override String toString() {
            return 'GROUP BY ' + String.format(this.groupByFunction, new List<String>{ String.join(this.groupByFields, ', ') });
        }
    }

    private class SoqlOrderBys implements QueryClause {
        public List<SoqlOrderBy> orderBys = new List<SoqlOrderBy>();

        public SoqlOrderBy newOrderBy() {
            this.orderBys.add(new SoqlOrderBy());
            return this.latestOrderBy();
        }

        public SoqlOrderBy latestOrderBy() {
            return this.orderBys.get(orderBys.size() - 1);
        }

        public override String toString() {
            List<String> orderFields = new List<String>();

            for (SoqlOrderBy orderBy : this.orderBys) {
                orderFields.add(orderBy.toString());
            }

            return 'ORDER BY ' + String.join(orderFields, ', ');
        }
    }

    private virtual class SoqlHavingFilterGroup extends FilterBuilder implements HavingFilterGroup {
        public HavingFilterGroup add(HavingFilterGroup filterGroup) {
            this.add(new HavingFilterGroupAdapter(filterGroup));
            return this;
        }

        public HavingFilterGroup add(HavingFilter filter) {
            this.add(new HavingFilterAdapter(filter));
            return this;
        }

        public HavingFilterGroup add(String filter) {
            this.add(new StringConditionAdapter(filter));
            return this;
        }

        public HavingFilterGroup anyConditionMatching() {
            this.connector = 'OR';
            return this;
        }

        public HavingFilterGroup conditionLogic(String order) {
            this.customOrder = order;
            return this;
        }

        public virtual override String toString() {
            return '(' + this.buildNested() + ')';
        }

        public Boolean hasValues() {
            return !this.conditions.isEmpty();
        }
    }

    private class MainHavingGroup extends SoqlHavingFilterGroup implements QueryClause {
        public override String toString() {
            return 'HAVING ' + this.buildNested();
        }
    }

    private class HavingFilterGroupAdapter implements FilterClause {
        private HavingFilterGroup havingFilterGroup;

        public HavingFilterGroupAdapter(HavingFilterGroup havingFilterGroup) {
            this.havingFilterGroup = havingFilterGroup;
        }

        public Boolean hasValue() {
            return this.havingFilterGroup.hasValues();
        }

        public override String toString() {
            return this.havingFilterGroup.toString();
        }
    }

    private class HavingFilterAdapter implements FilterClause {
        private HavingFilter havingFilter;

        public HavingFilterAdapter(HavingFilter havingFilter) {
            this.havingFilter = havingFilter;
        }

        public Boolean hasValue() {
            return this.havingFilter.hasValue();
        }

        public override String toString() {
            return this.havingFilter.toString();
        }
    }

    private class SoqlHavingFilter implements HavingFilter {
        private String field;
        private String comparator;
        private Object value;
        private String wrapper = '{0}';

        public HavingFilter with(SObjectField field) {
            return this.with(field.toString());
        }

        public HavingFilter with(String field) {
            this.field = field;
            return this;
        }

        public HavingFilter count(SObjectField field) {
            return this.withAggregateFunction('COUNT', field);
        }

        public HavingFilter avg(SObjectField field) {
            return this.withAggregateFunction('AVG', field);
        }

        public HavingFilter countDistinct(SObjectField field) {
            return this.withAggregateFunction('COUNT_DISTINCT', field);
        }

        public HavingFilter min(SObjectField field) {
            return this.withAggregateFunction('MIN', field);
        }

        public HavingFilter max(SObjectField field) {
            return this.withAggregateFunction('MAX', field);
        }

        public HavingFilter sum(SObjectField field) {
            return this.withAggregateFunction('SUM', field);
        }

        private HavingFilter withAggregateFunction(String aggregateFunction, SObjectField field) {
            return this.withAggregateFunction(aggregateFunction, field.toString());
        }

        private HavingFilter withAggregateFunction(String aggregateFunction, String field) {
            this.field = aggregateFunction + '(' + field + ')';
            return this;
        }

        public HavingFilter isNull() {
            return this.equal(null);
        }

        public HavingFilter isNotNull() {
            return this.notEqual(null);
        }

        public HavingFilter isTrue() {
            return this.equal(true);
        }

        public HavingFilter isFalse() {
            return this.equal(false);
        }

        public HavingFilter equal(Object value) {
            return this.set('=', value);
        }

        public HavingFilter notEqual(Object value) {
            return this.set('!=', value);
        }

        public HavingFilter lessThan(Object value) {
            return this.set('<', value);
        }

        public HavingFilter greaterThan(Object value) {
            return this.set('>', value);
        }

        public HavingFilter lessOrEqual(Object value) {
            return this.set('<=', value);
        }

        public HavingFilter greaterOrEqual(Object value) {
            return this.set('>=', value);
        }

        public HavingFilter contains(String value) {
            return this.contains('%', formattedString(value), '%');
        }

        public HavingFilter notContains(String value) {
            return this.notLike().contains(value);
        }

        public HavingFilter endsWith(String value) {
            return this.contains('%', formattedString(value), '');
        }

        public HavingFilter notEndsWith(String value) {
            return this.notLike().endsWith(value);
        }

        public HavingFilter startsWith(String value) {
            return this.contains('', formattedString(value), '%');
        }

        public HavingFilter notStartsWith(String value) {
            return this.notLike().startsWith(value);
        }

        public HavingFilter contains(String prefix, String value, String suffix) {
            return this.set('LIKE', prefix + formattedString(value) + suffix);
        }

        public HavingFilter notContains(String prefix, String value, String suffix) {
            return this.notLike().contains(prefix, value, suffix);
        }

        public HavingFilter isIn(Iterable<Object> iterable) {
            return this.set('IN', iterable);
        }

        public HavingFilter notIn(Iterable<Object> iterable) {
            return this.set('NOT IN', iterable);
        }

        private String formattedString(String value) {
            return value ?? value?.trim();
        }

        private HavingFilter notLike() {
            this.wrapper = '(NOT {0})';
            return this;
        }

        private HavingFilter set(String comparator, Object value) {
            this.comparator = comparator;
            this.value = value;
            return this;
        }

        public Boolean hasValue() {
            return String.isNotEmpty(this.field);
        }

        public override String toString() {
            return String.format(this.wrapper, new List<String>{ this.field + ' ' + this.comparator + ' :' + binder.bind(this.value) });
        }
    }

    private class SoqlOrderBy implements QueryClause {
        private String orderField;
        private String sortingOrder = 'ASC';
        private String nullsOrder = 'FIRST';

        public void with(String field) {
            this.orderField = field;
        }

        public void with(Distance distance) {
            this.orderField = distance.toString();
        }

        public void sortingOrder(String direction) {
            this.sortingOrder = direction;
        }

        public void nullsOrder(String nullsOrder) {
            this.nullsOrder = nullsOrder;
        }

        public override String toString() {
            return this.orderField + ' ' + this.sortingOrder + ' NULLS ' + this.nullsOrder;
        }
    }

    private class SoqlLimit implements QueryClause {
        private Integer soqlLimit;

        public void set(Integer soqlLimit) {
            this.soqlLimit = soqlLimit;
        }

        public override String toString() {
            return 'LIMIT ' + this.soqlLimit;
        }
    }

    private class SoqlOffset implements QueryClause {
        private Integer soqlOffset;

        public void set(Integer fromRow) {
            this.soqlOffset = fromRow;
        }

        public override String toString() {
            return 'OFFSET ' + this.soqlOffset;
        }
    }

    private class SoqlFor implements QueryClause {
        private String forStatement;

        public void set(String forStatement) {
            this.forStatement = forStatement;
        }

        public override String toString() {
            return this.forStatement;
        }
    }

    private class Binder {
        private Integer bindIndex = 0;
        private Map<String, Object> binding = new Map<String, Object>();

        public String bind(Object value) {
            bindIndex++;
            binding.put('v' + bindIndex, value);
            return 'v' + bindIndex;
        }

        public void reset() {
            this.bindIndex = 0;
            this.binding.clear();
        }

        public Map<String, Object> getBindingMap() {
            return binding;
        }
    }

    private class SoqlMock implements Mockable {
        public SObjectMock sObjectMock = new SObjectMock();
        public CountMock countMock = new CountMock();
        public AggregateResultProxies aggregateResultMock = new AggregateResultProxies();
        public ExceptionMock exceptionMock = null;

        public Mockable thenReturn(List<Map<String, Object>> aggregatedResults) {
            this.aggregateResultMock.add(aggregatedResults);
            return this;
        }

        public Mockable thenReturn(Map<String, Object> aggregatedResult) {
            this.aggregateResultMock.add(aggregatedResult);
            return this;
        }

        public Mockable thenReturn(SObject record) {
            this.sObjectMock.add(record);
            return this;
        }

        public Mockable thenReturn(List<SObject> records) {
            this.sObjectMock.add(records);
            return this;
        }

        public Mockable thenReturn(Integer count) {
            this.countMock.set(count);
            return this;
        }

        public void throwException() {
            throwException('List has no rows for assignment to SObject');
        }

        public void throwException(String message) {
            this.exceptionMock = new ExceptionMock();
            this.exceptionMock.set(new QueryException(message));
        }

        public Boolean hasExceptionMock() {
            return this.exceptionMock != null;
        }

        public SoqlMock useLegacyMockingBehavior() {
            this.sObjectMock.useLegacyMockingBehavior = true;
            return this;
        }
    }

    private class SObjectMock {
        private List<SObject> mockedRecords;
        private Boolean useLegacyMockingBehavior = false;
        private SObjectType sObjectType;

        private void add(SObject record) {
            this.sObjectType = record?.getSObjectType();
            this.initializeRecords();
            this.mockedRecords.add(record);
        }

        private void add(List<SObject> records) {
            this.sObjectType = records?.getSObjectType();
            this.initializeRecords();
            this.mockedRecords.addAll(records);
        }

        private void initializeRecords() {
            if (this.mockedRecords != null) {
                return;
            }

            this.mockedRecords = (List<SObject>) Type.forName('List<' + (this.sObjectType != null ? 'Schema.' + this.sObjectType?.toString() : 'SObject') + ' >').newInstance();
        }

        private List<SObject> get(SoqlFields fields, SoqlSubQueries subQueries) {
            if (this.useLegacyMockingBehavior || this.mockedRecords.isEmpty() || this.sObjectType == AggregateResult.SObjectType) {
                return this.mockedRecords;
            }

            if (!fields.aggregateFields.isEmpty()) {
                throw new QueryException('Use toAggregatedProxy() to mock AggregateResult records.');
            }

            this.addIdToMockedRecords();

            if (!fields.relationshipFields.isEmpty() || !fields.functionsFields.isEmpty() || !fields.typeOfFields.isEmpty()) {
                return this.mockedRecords;
            }

            return this.stripAdditionalFields(fields.plainFields.get(), subQueries.get());
        }

        private List<AggregateResult> getAggregated(String fieldToExtract) {
            if (this.mockedRecords.isEmpty()) {
                return new List<AggregateResult>();
            }

            // used only for toIdsOf and toValueOf, because only Id can be set in the AggregateResult
            List<Map<String, Object>> aggregatedResults = new List<Map<String, Object>>();

            Set<String> values = new Converter(this.mockedRecords[0].getSObjectType().toString()).transform(this.mockedRecords).toValuesOf(fieldToExtract);

            for (String value : values) {
                aggregatedResults.add(new Map<String, Object>{ 'Id' => value });
            }

            return (List<AggregateResult>) JSON.deserialize(JSON.serialize(aggregatedResults), List<AggregateResult>.class);
        }

        private void addIdToMockedRecords() {
            // Id is added to mirror standard rflib_SOQL behavior
            SObjectType sObjectType = this.mockedRecords[0].getSObjectType();
            String sObjectPrefix = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix();

            if (String.isBlank(sObjectPrefix)) {
                return;
            }

            for (SObject record : this.mockedRecords) {
                record.put('Id', record?.Id ?? IdGenerator.get(sObjectPrefix));
            }
        }

        private List<SObject> stripAdditionalFields(Set<String> requestedFields, Set<String> subQueriesRelationshipNames) {
            Type objectTypeName = Type.forName(this.sObjectType?.toString() ?? 'SObject');

            List<SObject> cleanedRecords = (List<SObject>) Type.forName('List<' + (this.sObjectType != null ? 'Schema.' + this.sObjectType.toString() : 'SObject') + ' >')
                .newInstance();

            for (SObject record : this.mockedRecords) {
                Map<String, Object> recordFilteredFields = new Map<String, Object>{ 'Id' => record.Id };

                this.stripAdditionalPlainFields(recordFilteredFields, record, requestedFields);
                this.stripAdditionalSubQueries(recordFilteredFields, record, subQueriesRelationshipNames);

                try {
                    // JSON.serialize and JSON.deserialize are used to copy not writable fields
                    cleanedRecords.add((SObject) JSON.deserialize(JSON.serialize(recordFilteredFields), objectTypeName));
                } catch (System.JSONException e) {
                    // fallback when object has Base64 field which is not supported by JSON.deserialize
                    cleanedRecords.add(record);
                }
            }

            return cleanedRecords;
        }

        private void stripAdditionalPlainFields(Map<String, Object> recordFilteredFields, SObject record, Set<String> requestedFields) {
            for (String field : requestedFields) {
                recordFilteredFields.put(field, record.get(field));
            }
        }

        private void stripAdditionalSubQueries(Map<String, Object> recordFilteredFields, SObject record, Set<String> subQueriesRelationshipNames) {
            for (String subQueryRelationshipName : subQueriesRelationshipNames) {
                recordFilteredFields.put(
                    subQueryRelationshipName,
                    new Map<String, Object>{
                        'totalSize' => record.getSObjects(subQueryRelationshipName)?.size() ?? 0,
                        'done' => true,
                        'records' => record.getSObjects(subQueryRelationshipName) ?? new List<SObject>()
                    }
                );
            }
        }
    }

    private class CountMock {
        private Integer countMock;

        private void set(Integer count) {
            this.countMock = count;
        }

        private Integer get() {
            return this.countMock;
        }
    }

    private class AggregateResultProxies {
        private List<AggregateResultProxy> aggregateResults = new List<AggregateResultProxy>();

        public AggregateResultProxies add(List<AggregateResult> aggregateResults) {
            for (AggregateResult result : aggregateResults) {
                this.aggregateResults.add(new SoqlAggregateResultProxy(result));
            }
            return this;
        }

        public AggregateResultProxies add(List<Map<String, Object>> aggregateResults) {
            for (Map<String, Object> result : aggregateResults) {
                this.add(result);
            }
            return this;
        }

        public AggregateResultProxies add(Map<String, Object> aggregateResult) {
            this.aggregateResults.add(new SoqlAggregateResultProxy(aggregateResult));
            return this;
        }

        public List<AggregateResultProxy> get() {
            return this.aggregateResults;
        }
    }

    private class SoqlAggregateResultProxy implements AggregateResultProxy {
        private Map<String, Object> aggregateResult;

        public SoqlAggregateResultProxy(AggregateResult aggregateResult) {
            this.aggregateResult = aggregateResult.getPopulatedFieldsAsMap();
        }

        public SoqlAggregateResultProxy(Map<String, Object> aggregateResult) {
            this.aggregateResult = aggregateResult;
        }

        public Object get(String field) {
            return this.aggregateResult.get(field);
        }

        public Map<String, Object> getPopulatedFieldsAsMap() {
            return this.aggregateResult;
        }
    }

    private class SoqlDistance implements Distance {
        private String field;
        private String unit = 'km';
        private String comparisonLocation;

        public Distance of(SObjectField ofField) {
            this.field = ofField.toString();
            return this;
        }

        public Distance of(String relationship, SObjectField ofField) {
            this.field = relationship + '.' + ofField.toString();
            return this;
        }

        public Distance between(System.Location location) {
            this.comparisonLocation = 'GEOLOCATION(' + location.getLatitude() + ',' + location.getLongitude() + ')';
            return this;
        }

        public Distance between(Decimal latitude, Decimal longitude) {
            return this.between(Location.newInstance(latitude, longitude));
        }

        public Distance mi() {
            return this.unit('mi');
        }

        public Distance km() {
            return this.unit('km');
        }

        private Distance unit(String unit) {
            this.unit = unit;
            return this;
        }

        public override String toString() {
            return 'DISTANCE(' + this.field + ', ' + this.comparisonLocation + ', \'' + this.unit + '\')';
        }
    }

    private class ExceptionMock {
        private QueryException queryException;

        public void set(QueryException queryException) {
            this.queryException = queryException;
        }

        public QueryException get() {
            return this.queryException;
        }
    }

    private class SoqlError implements Error {
        public Exception queryException;
        public String query;
        public Map<String, Object> binding;
        public AccessLevel accessLevel;

        public Exception getException() {
            return this.queryException;
        }

        public String getQuery() {
            return this.query;
        }

        public Map<String, Object> getBinding() {
            return this.binding;
        }

        public AccessLevel getAccessLevel() {
            return this.accessLevel;
        }
    }

    private inherited sharing class Executor {
        private DatabaseQuery sharingExecutor;
        private AccessLevel accessMode;
        private AccessType accessType;
        private Builder builder;
        private List<SoqlMock> mocks = new List<SoqlMock>();

        public Executor(Builder builder) {
            this.builder = builder;
            this.accessMode = AccessLevel.USER_MODE;
            this.sharingExecutor = new InheritedSharing();
        }

        public void withSharing() {
            this.sharingExecutor = new WithSharing();
        }

        public void withoutSharing() {
            this.sharingExecutor = new WithoutSharing();
        }

        public void stripInaccessible(AccessType type) {
            this.accessType = type;
        }

        public void accessMode(AccessLevel accessMode) {
            this.accessMode = accessMode;
        }

        public void mock(List<SoqlMock> mocks) {
            this.mocks = mocks ?? new List<SoqlMock>();
        }

        public SObject toObject() {
            List<SObject> records = toList();

            if (records.isEmpty()) {
                return null; // handle: List has no rows for assignment to SObject
            }

            if (records.size() > 1) {
                throw new QueryException('List has more than 1 row for assignment to SObject');
            }

            return records[0];
        }

        public List<SObject> toList() {
            this.incrementQueryIssued();

            if (!this.mocks.isEmpty()) {
                this.throwExceptionMockIfExists();
                return this.getMockedListProxy();
            }

            String query = this.builder.toString();

            try {
                if (this.accessType == null) {
                    return this.sharingExecutor.toSObjects(query, binder.getBindingMap(), this.accessMode);
                }

                return System.Security.stripInaccessible(this.accessType, this.sharingExecutor.toSObjects(query, binder.getBindingMap(), this.accessMode)).getRecords();
            } catch (Exception e) {
                this.logError(e, query);
                throw e;
            }
        }

        private void throwExceptionMockIfExists() {
            if (this.mocks[0].hasExceptionMock()) {
                throw this.mocks[0].exceptionMock.get();
            }
        }

        private List<SObject> getMockedListProxy() {
            if (this.mocks.size() == 1) {
                return this.mocks[0].sObjectMock.get(this.builder.fields, this.builder.subQueries);
            }
            return this.mocks.remove(0).sObjectMock.get(this.builder.fields, this.builder.subQueries);
        }

        public List<AggregateResult> toAggregated(String fieldToExtract) {
            // Used only for toIdsOf and toValuesOf, because only Id can be set in the AggregateResult
            if (!this.mocks.isEmpty()) {
                this.throwExceptionMockIfExists();
                return this.getMockedAggregatedResult(fieldToExtract);
            }

            String query = this.builder.toString();

            try {
                if (this.accessType == null) {
                    return this.sharingExecutor.toSObjects(query, binder.getBindingMap(), this.accessMode);
                }

                return System.Security.stripInaccessible(this.accessType, this.sharingExecutor.toSObjects(query, binder.getBindingMap(), this.accessMode)).getRecords();
            } catch (Exception e) {
                this.logError(e, query);
                throw e;
            }
        }

        private List<AggregateResult> getMockedAggregatedResult(String fieldToExtract) {
            // Used only for toIdsOf and toValueOf, because only Id can be set in the AggregateResult
            if (this.mocks.size() == 1) {
                return (List<AggregateResult>) this.mocks[0].sObjectMock.getAggregated(fieldToExtract);
            }

            return (List<AggregateResult>) this.mocks.remove(0).sObjectMock.getAggregated(fieldToExtract);
        }

        public List<AggregateResultProxy> toAggregatedProxy() {
            if (!this.mocks.isEmpty()) {
                this.throwExceptionMockIfExists();
                return this.getMockedAggregateProxy();
            }

            return new AggregateResultProxies().add(this.toList()).get();
        }

        private List<AggregateResultProxy> getMockedAggregateProxy() {
            if (this.mocks.size() == 1) {
                return this.mocks[0].aggregateResultMock.get();
            }
            return this.mocks.remove(0).aggregateResultMock.get();
        }

        public Integer toInteger() {
            this.incrementQueryIssued();

            if (!this.mocks.isEmpty()) {
                this.throwExceptionMockIfExists();
                return this.getMockedCount();
            }

            String query = this.builder.toString();

            try {
                return this.sharingExecutor.toInteger(query, binder.getBindingMap(), this.accessMode);
            } catch (Exception e) {
                this.logError(e, query);
                throw e;
            }
        }

        private Integer getMockedCount() {
            if (this.mocks.size() == 1) {
                return this.mocks[0].countMock.get();
            }
            return this.mocks.remove(0).countMock.get();
        }

        public Database.QueryLocator toQueryLocator() {
            this.incrementQueryIssued();

            String query = this.builder.toString();

            try {
                return this.sharingExecutor.toQueryLocator(query, binder.getBindingMap(), this.accessMode);
            } catch (Exception e) {
                this.logError(e, query);
                throw e;
            }
        }

        public Database.Cursor toCursor() {
            this.incrementQueryIssued();

            String query = this.builder.toString();

            try {
                return this.sharingExecutor.toCursor(query, binder.getBindingMap(), this.accessMode);
            } catch (Exception e) {
                this.logError(e, query);
                throw e;
            }
        }

        public Database.PaginationCursor toPaginationCursor() {
            this.incrementQueryIssued();

            String query = this.builder.toString();

            try {
                return this.sharingExecutor.toPaginationCursor(query, binder.getBindingMap(), this.accessMode);
            } catch (Exception e) {
                this.logError(e, query);
                throw e;
            }
        }

        private void logError(Exception e, String query) {
            if (rflib_SOQL.queryLogger == null) {
                return;
            }

            SoqlError queryError = new SoqlError();

            queryError.queryException = e;
            queryError.query = query;
            queryError.binding = binder.getBindingMap();
            queryError.accessLevel = this.accessMode;

            rflib_SOQL.queryLogger.log(queryError);
        }

        private void incrementQueryIssued() {
            // This counter is used only in unit tests to also track mocked queries.
            if (!System.Test.isRunningTest() || System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled()) {
                return;
            }

            rflib_SOQL.syncQueriesIssued++;

            final Integer maxQueriesIssuedInSynchronousTransaction = 100;

            if (rflib_SOQL.syncQueriesIssued > maxQueriesIssuedInSynchronousTransaction) {
                throw new QueryException('Too many rflib_SOQL queries.');
            }
        }
    }

    private interface DatabaseQuery {
        List<SObject> toSObjects(String query, Map<String, Object> binding, AccessLevel accessLevel);
        Integer toInteger(String query, Map<String, Object> binding, AccessLevel accessLevel);
        Database.QueryLocator toQueryLocator(String query, Map<String, Object> binding, AccessLevel accessLevel);
        Database.Cursor toCursor(String query, Map<String, Object> binding, AccessLevel accessLevel);
        Database.PaginationCursor toPaginationCursor(String query, Map<String, Object> binding, AccessLevel accessLevel);
    }

    private inherited sharing class InheritedSharing implements DatabaseQuery {
        public List<SObject> toSObjects(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, binding, accessLevel);
        }

        public Integer toInteger(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.countQueryWithBinds(query, binding, accessLevel);
        }

        public Database.QueryLocator toQueryLocator(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, binding, accessLevel);
        }

        public Database.Cursor toCursor(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getCursorWithBinds(query, binding, accessLevel);
        }

        public Database.PaginationCursor toPaginationCursor(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getPaginationCursorWithBinds(query, binding, accessLevel);
        }
    }

    private without sharing class WithoutSharing implements DatabaseQuery {
        public List<SObject> toSObjects(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, binding, accessLevel);
        }

        public Integer toInteger(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.countQueryWithBinds(query, binding, accessLevel);
        }

        public Database.QueryLocator toQueryLocator(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, binding, accessLevel);
        }

        public Database.Cursor toCursor(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getCursorWithBinds(query, binding, accessLevel);
        }

        public Database.PaginationCursor toPaginationCursor(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getPaginationCursorWithBinds(query, binding, accessLevel);
        }
    }

    private with sharing class WithSharing implements DatabaseQuery {
        public List<SObject> toSObjects(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.queryWithBinds(query, binding, accessLevel);
        }

        public Integer toInteger(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.countQueryWithBinds(query, binding, accessLevel);
        }

        public Database.QueryLocator toQueryLocator(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getQueryLocatorWithBinds(query, binding, accessLevel);
        }

        public Database.Cursor toCursor(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getCursorWithBinds(query, binding, accessLevel);
        }

        public Database.PaginationCursor toPaginationCursor(String query, Map<String, Object> binding, AccessLevel accessLevel) {
            return Database.getPaginationCursorWithBinds(query, binding, accessLevel);
        }
    }

    public inherited sharing class Converter {
        private String ofObject;
        private List<SObject> recordsToTransform;

        public Converter(String ofObject) {
            this.ofObject = ofObject;
        }

        public Converter transform(List<SObject> recordsToTransform) {
            this.recordsToTransform = recordsToTransform;
            return this;
        }

        public Map<Id, SObject> toMap() {
            Map<Id, SObject> recordPerId = (Map<Id, SObject>) Type.forName('Map<Id, ' + this.ofObject + ' >').newInstance();
            recordPerId.putAll(this.recordsToTransform);
            return recordPerId;
        }

        public Map<Id, SObject> toIdMapBy(SObjectField field) {
            return this.toIdMapBy(field.toString());
        }

        public Map<Id, SObject> toIdMapBy(String relationshipName, SObjectField targetKeyField) {
            return this.toIdMapBy(relationshipName + '.' + targetKeyField.toString());
        }

        public Map<Id, SObject> toIdMapBy(String fieldPath) {
            Map<Id, SObject> recordPerCustomKey = (Map<Id, SObject>) Type.forName('Map<Id, ' + this.ofObject + ' >').newInstance();
            List<String> relationshipPathFields = fieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                recordPerCustomKey.put(extractNestedFieldValue(record, relationshipPathFields, targetField), record);
            }

            return recordPerCustomKey;
        }

        public Map<Id, List<SObject>> toAggregatedIdMapBy(SObjectField keyField) {
            return this.toAggregatedIdMapBy(keyField.toString());
        }

        public Map<Id, List<SObject>> toAggregatedIdMapBy(String relationshipName, SObjectField targetKeyField) {
            return this.toAggregatedIdMapBy(relationshipName + '.' + targetKeyField.toString());
        }

        private Map<Id, List<SObject>> toAggregatedIdMapBy(String keyFieldPath) {
            Map<Id, List<SObject>> recordsPerCustomKey = (Map<Id, List<SObject>>) Type.forName('Map<Id, List<' + this.ofObject + ' >>').newInstance();
            List<String> relationshipPathFields = keyFieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                Id key = extractNestedFieldValue(record, relationshipPathFields, targetField);

                if (!recordsPerCustomKey.containsKey(key)) {
                    recordsPerCustomKey.put(key, new List<SObject>());
                }

                recordsPerCustomKey.get(key).add(record);
            }

            return recordsPerCustomKey;
        }

        public Map<String, SObject> toMap(SObjectField keyField) {
            return this.toMap(keyField.toString());
        }

        public Map<String, SObject> toMap(String relationshipName, SObjectField keyField) {
            return this.toMap(relationshipName + '.' + keyField.toString());
        }

        public Map<String, SObject> toMap(String fieldPath) {
            Map<String, SObject> recordPerCustomKey = (Map<String, SObject>) Type.forName('Map<String, ' + this.ofObject + ' >').newInstance();
            List<String> relationshipPathFields = fieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                String key = extractNestedFieldValue(record, relationshipPathFields, targetField);
                recordPerCustomKey.put(key, record);
            }

            return recordPerCustomKey;
        }

        public Map<String, String> toMap(SObjectField keyField, SObjectField valueField) {
            Map<String, String> customValuePerCustomKey = new Map<String, String>();

            for (SObject record : this.recordsToTransform) {
                customValuePerCustomKey.put(record.get(keyField).toString(), record.get(valueField)?.toString());
            }

            return customValuePerCustomKey;
        }

        public Map<String, String> toMap(SObjectField keyField, String relationshipName, SObjectField targetKeyField) {
            return this.toMap(keyField, relationshipName + '.' + targetKeyField.toString());
        }

        private Map<String, String> toMap(SObjectField keyField, String targetFieldPath) {
            Map<String, String> customValuePerCustomKey = new Map<String, String>();
            List<String> relationshipPathFields = targetFieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                customValuePerCustomKey.put(String.valueOf(record.get(keyField)), extractNestedFieldValue(record, relationshipPathFields, targetField));
            }

            return customValuePerCustomKey;
        }

        public Set<Id> toIdsOf(SObjectField field) {
            return this.toIdsOf(field.toString());
        }

        public Set<Id> toIdsOf(String relationshipName, SObjectField field) {
            return this.toIdsOf(relationshipName + '.' + field.toString());
        }

        public Set<Id> toIdsOf(String fieldPath) {
            Set<Id> ids = new Set<Id>();

            List<String> relationshipPathFields = fieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                ids.add(extractNestedFieldValue(record, relationshipPathFields, targetField));
            }

            return ids;
        }

        public Set<String> toValuesOf(SObjectField fieldToExtract) {
            return this.toValuesOf(fieldToExtract.toString());
        }

        public Set<String> toValuesOf(String fieldToExtract) {
            Set<String> values = new Set<String>();
            List<String> relationshipPathFields = fieldToExtract.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                values.add(extractNestedFieldValue(record, relationshipPathFields, targetField));
            }

            return values;
        }

        public Map<String, List<SObject>> toAggregatedMap(SObjectField keyField) {
            return this.toSObjectAggregatedMap(keyField, keyField.toString());
        }

        public Map<String, List<SObject>> toAggregatedMap(String relationshipName, SObjectField keyField) {
            return this.toSObjectAggregatedMap(keyField, relationshipName + '.' + keyField.toString());
        }

        private Map<String, List<SObject>> toSObjectAggregatedMap(SObjectField keyField, String keyFieldPath) {
            Map<String, List<SObject>> recordsPerCustomKey = (Map<String, List<SObject>>) Type.forName('Map<String, List<' + this.ofObject + ' >>').newInstance();
            List<String> relationshipPathFields = keyFieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                String key = extractNestedFieldValue(record, relationshipPathFields, targetField);

                if (!recordsPerCustomKey.containsKey(key)) {
                    recordsPerCustomKey.put(key, new List<SObject>());
                }

                recordsPerCustomKey.get(key).add(record);
            }

            return recordsPerCustomKey;
        }

        public Map<String, List<String>> toAggregatedMap(SObjectField keyField, SObjectField valueField) {
            return this.toAggregatedMap(keyField, valueField.toString());
        }

        public Map<String, List<String>> toAggregatedMap(SObjectField keyField, String relationshipName, SObjectField targetKeyField) {
            return this.toAggregatedMap(keyField, relationshipName + '.' + targetKeyField.toString());
        }

        private Map<String, List<String>> toAggregatedMap(SObjectField keyField, String targetFieldPath) {
            Map<String, List<String>> customValuesPerCustomKey = new Map<String, List<String>>();
            List<String> relationshipPathFields = targetFieldPath.split('\\.');
            String targetField = relationshipPathFields.remove(relationshipPathFields.size() - 1);

            for (SObject record : this.recordsToTransform) {
                String key = String.valueOf(record.get(keyField));
                String value = extractNestedFieldValue(record, relationshipPathFields, targetField);

                if (!customValuesPerCustomKey.containsKey(key)) {
                    customValuesPerCustomKey.put(key, new List<String>());
                }

                customValuesPerCustomKey.get(key).add(value);
            }

            return customValuesPerCustomKey;
        }

        private String extractNestedFieldValue(SObject parentRecord, List<String> relationshipPath, String targetField) {
            SObject currentRecord = parentRecord;

            for (String relationshipField : relationshipPath) {
                currentRecord = currentRecord.getSObject(relationshipField);

                if (currentRecord == null) {
                    return null;
                }
            }

            return currentRecord.get(targetField)?.toString();
        }
    }

    public class RandomIdGenerator {
        private final String RANDOM_STRING_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';

        public Id get(SObjectType objectType) {
            return get(objectType.getDescribe().getKeyPrefix());
        }

        public Id get(String prefix) {
            String randomPart = '';

            while (randomPart.length() < 8) {
                Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), RANDOM_STRING_CHARACTERS.length());
                randomPart += RANDOM_STRING_CHARACTERS.substring(idx, idx + 1);
            }

            return Id.valueOf(prefix + '0000' + randomPart);
        }
    }
}
