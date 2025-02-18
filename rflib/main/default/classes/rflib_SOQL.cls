/**
 * Copyright (c) 2025 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/soql-lib/blob/main/LICENSE)
 *
 * PMD False Positives:
 * - ExcessivePublicCount: It is a library class and exposes all necessary methods to construct a query
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE class
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE class
 * - PropertyNamingConventions: It was intentional to make the lib more fluent and readable
 * - FieldDeclarationsShouldBeAtStart: Developer who uses lib should see what's important at start
 * - ApexDoc: Variable names are self-documented.
 * - ExcessiveParameterList - Make methods similar to native rflib_SOQL
**/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.PropertyNamingConventions, PMD.FieldDeclarationsShouldBeAtStart, PMD.ApexDoc, PMD.ExcessiveParameterList, PMD.ClassNamingConventions')
public virtual inherited sharing class rflib_SOQL implements Queryable {
    public interface Selector {
        Queryable query();
    }

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
        Queryable toLabel(String field);
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
        // GROUP BY
        Queryable groupBy(SObjectField field);
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
        // ORDER BY
        Queryable orderBy(String field);
        Queryable orderBy(String field, String direction);
        Queryable orderBy(SObjectField field);
        Queryable orderBy(String relationshipName, SObjectField field);
        Queryable sortDesc();
        Queryable nullsLast();
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
        // PREDEFINIED
        Queryable byId(SObject record);
        Queryable byId(Id recordId);
        Queryable byIds(Iterable<Id> recordIds);
        Queryable byIds(List<SObject> records);
        Queryable byRecordType(String recordTypeDeveloperName);
        // RESULT
        Id toId();
        Boolean doExist();
        String toString();
        Object toValueOf(SObjectField fieldToExtract);
        Set<String> toValuesOf(SObjectField fieldToExtract);
        Integer toInteger();
        SObject toObject();
        List<SObject> toList();
        List<AggregateResult> toAggregated();
        Map<Id, SObject> toMap();
        Map<String, SObject> toMap(SObjectField keyField);
        Map<String, String> toMap(SObjectField keyField, SObjectField valueField);
        Map<String, List<SObject>> toAggregatedMap(SObjectField keyField);
        Map<String, List<String>> toAggregatedMap(SObjectField keyField, SObjectField valueField);
        Database.QueryLocator toQueryLocator();
    }

    public interface SubQuery {
        SubQuery of(String ofObject);
        // SELECT
        SubQuery with(SObjectField field);
        SubQuery with(SObjectField field1, SObjectField field2);
        SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3);
        SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        SubQuery with(Iterable<SObjectField> fields);
        SubQuery with(String relationshipName, Iterable<SObjectField> fields);
        SubQuery with(SubQuery subQuery);
        // WHERE
        SubQuery whereAre(FilterGroup filterGroup);
        SubQuery whereAre(Filter filter);
        //ORDER BY
        SubQuery orderBy(SObjectField field);
        SubQuery orderBy(String relationshipName, SObjectField field);
        SubQuery sortDesc();
        SubQuery nullsLast();
        // LIMIT
        SubQuery setLimit(Integer amount);
        // OFFSET
        SubQuery offset(Integer startingRow);
        // FOR
        SubQuery forReference();
        SubQuery forView();
    }

    public interface FilterGroup {
        // ADD CONDITION
        FilterGroup add(FilterGroup filterGroup);
        FilterGroup add(Filter filter);
        FilterGroup add(String dynamicCondition);
        // ORDER
        FilterGroup anyConditionMatching();
        FilterGroup conditionLogic(String order);
        // ADDITIONAL
        FilterGroup ignoreWhen(Boolean logicExpression);

        Boolean hasValues();
    }

    public interface Filter {
        // FIELDS
        Filter id();
        Filter recordType();
        Filter name();
        Filter with(SObjectField field);
        Filter with(String field);
        Filter with(String relationshipName, SObjectField field);
        // COMPERATORS
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
        Filter notIn(Iterable<Object> iterable);
        Filter notIn(InnerJoin joinQuery);
        Filter includesAll(Iterable<String> values);
        Filter includesSome(Iterable<String> values);
        Filter excludesAll(Iterable<String> values);
        Filter excludesSome(Iterable<String> values);
        // ADDITIONAL
        Filter asDateLiteral();
        Filter ignoreWhen(Boolean logicExpression);

        Boolean hasValue();
    }

    public interface InnerJoin {
        InnerJoin of(SObjectType ofObject);
        // SELECT
        InnerJoin with(SObjectField field);
        // WHERE
        InnerJoin whereAre(FilterGroup filterGroup);
        InnerJoin whereAre(Filter filter);
    }

    public interface HavingFilterGroup {
        // ADD CONDITION
        HavingFilterGroup add(HavingFilterGroup havingFilterGroup);
        HavingFilterGroup add(HavingFilter havingFilter);
        HavingFilterGroup add(String dynamicHaving);
        // ORDER
        HavingFilterGroup anyConditionMatching();
        HavingFilterGroup conditionLogic(String order);
    }

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
        // COMPERATORS
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
    }

    public static SubQuery SubQuery {
        get { return new SoqlSubQuery(); }
    }

    public static FilterGroup FilterGroup {
        get { return new SoqlFilterGroup(); }
    }

    public static Filter Filter {
        get { return new SoqlFilter(); }
    }

    public static InnerJoin InnerJoin {
        get { return new SoqlJoinQuery(); }
    }

    public static HavingFilterGroup HavingFilterGroup {
        get { return new SoqlHavingFilterGroup(); }
    }

    public static HavingFilter HavingFilter {
        get { return new SoqlHavingFilter(); }
    }

    @TestVisible
    private static void setMock(String mockId, SObject record) {
        setMock(mockId, new List<SObject>{ record });
    }

    @TestVisible
    private static void setMock(String mockId, List<SObject> records) {
        mock.setMock(mockId, records);
    }

    @TestVisible
    private static void setCountMock(String mockId, Integer amount) {
        mock.setCountMock(mockId, amount);
    }

    // Implementation

    private static Mock mock = new Mock();
    private static Binder binder = new Binder();

    private SoqlBuilder builder;
    private Executor executor;

    public static rflib_SOQL of(SObjectType ofObject) {
        return new rflib_SOQL(ofObject);
    }

    public static rflib_SOQL of(String ofObject) {
        return new rflib_SOQL(ofObject);
    }

    public rflib_SOQL(SObjectType ofObject) {
        this(ofObject.getDescribe().getName());
    }

    public rflib_SOQL(String ofObject) {
        builder = new SoqlBuilder(ofObject);
        executor = new Executor(ofObject, builder);
    }

    public rflib_SOQL with(SObjectField field) {
        builder.fields.with(field);
        return this;
    }

    public rflib_SOQL with(SObjectField field1, SObjectField field2) {
        return with(field1).with(field2);
    }

    public rflib_SOQL with(SObjectField field1, SObjectField field2, SObjectField field3) {
        return with(field1, field2).with(field3);
    }

    public rflib_SOQL with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return with(field1, field2, field3).with(field4);
    }

    public rflib_SOQL with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
        return with(field1, field2, field3, field4).with(field5);
    }

    public rflib_SOQL with(List<SObjectField> fields) {
        builder.fields.with(fields);
        return this;
    }

    public rflib_SOQL with(Iterable<String> fields) {
        return with(String.join(fields, ','));
    }

    public rflib_SOQL withFieldSet(String fieldSetName) {
        builder.fields.withFieldSet(fieldSetName);
        return this;
    }

    public rflib_SOQL with(String fields) {
        builder.fields.with(fields);
        return this;
    }

    public rflib_SOQL with(SObjectField field, String alias) {
        builder.fields.with(field, alias);
        return this;
    }

    public rflib_SOQL with(String relationshipName, SObjectField field) {
        return with(relationshipName, new List<SObjectField>{ field });
    }

    public rflib_SOQL with(String relationshipName, SObjectField field1, SObjectField field2) {
        return with(relationshipName, new List<SObjectField>{ field1, field2 });
    }

    public rflib_SOQL with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
        return with(relationshipName, new List<SObjectField>{ field1, field2, field3 });
    }

    public rflib_SOQL with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return with(relationshipName, new List<SObjectField>{ field1, field2, field3, field4 });
    }

    public rflib_SOQL with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
        return with(relationshipName, new List<SObjectField>{ field1, field2, field3, field4, field5 });
    }

    public rflib_SOQL with(String relationshipName, Iterable<SObjectField> fields) {
        builder.fields.with(relationshipName, fields);
        return this;
    }

    public rflib_SOQL with(SubQuery subQuery) {
        builder.subQueries.add(subQuery);
        return this;
    }

    public rflib_SOQL count() {
        builder.fields.count();
        return this;
    }

    public rflib_SOQL count(SObjectField field) {
        return count(field, '');
    }

    public rflib_SOQL count(SObjectField field, String alias) {
        builder.fields.count(field, alias);
        return this;
    }

    public rflib_SOQL count(String relationshipName, SObjectField field) {
        return count(relationshipName, field, '');
    }

    public rflib_SOQL count(String relationshipName, SObjectField field, String alias) {
        builder.fields.count(relationshipName, field, alias);
        return this;
    }

    public rflib_SOQL avg(SObjectField field) {
        return avg(field, '');
    }

    public rflib_SOQL avg(SObjectField field, String alias) {
        builder.fields.avg(field, alias);
        return this;
    }

    public rflib_SOQL avg(String relationshipName, SObjectField field) {
        return avg(relationshipName, field, '');
    }

    public rflib_SOQL avg(String relationshipName, SObjectField field, String alias) {
        builder.fields.avg(relationshipName, field, alias);
        return this;
    }

    public rflib_SOQL countDistinct(SObjectField field) {
        return countDistinct(field, '');
    }

    public rflib_SOQL countDistinct(SObjectField field, String alias) {
        builder.fields.countDistinct(field, alias);
        return this;
    }

    public rflib_SOQL countDistinct(String relationshipName, SObjectField field) {
        return countDistinct(relationshipName, field, '');
    }

    public rflib_SOQL countDistinct(String relationshipName, SObjectField field, String alias) {
        builder.fields.countDistinct(relationshipName, field, alias);
        return this;
    }

    public rflib_SOQL min(SObjectField field) {
        return min(field, '');
    }

    public rflib_SOQL min(SObjectField field, String alias) {
        builder.fields.min(field, alias);
        return this;
    }

    public rflib_SOQL min(String relationshipName, SObjectField field) {
        return min(relationshipName, field, '');
    }

    public rflib_SOQL min(String relationshipName, SObjectField field, String alias) {
        builder.fields.min(relationshipName, field, alias);
        return this;
    }

    public rflib_SOQL max(SObjectField field) {
        return max(field, '');
    }

    public rflib_SOQL max(SObjectField field, String alias) {
        builder.fields.max(field, alias);
        return this;
    }

    public rflib_SOQL max(String relationshipName, SObjectField field) {
        return max(relationshipName, field, '');
    }

    public rflib_SOQL max(String relationshipName, SObjectField field, String alias) {
        builder.fields.max(relationshipName, field, alias);
        return this;
    }

    public rflib_SOQL sum(SObjectField field) {
        return sum(field, '');
    }

    public rflib_SOQL sum(SObjectField field, String alias) {
        builder.fields.sum(field, alias);
        return this;
    }

    public rflib_SOQL sum(String relationshipName, SObjectField field) {
        return sum(relationshipName, field, '');
    }

    public rflib_SOQL sum(String relationshipName, SObjectField field, String alias) {
        builder.fields.sum(relationshipName, field, alias);
        return this;
    }

    public rflib_SOQL grouping(SObjectField field, String alias) {
        builder.fields.grouping(field, alias);
        return this;
    }

    public rflib_SOQL toLabel(SObjectField field) {
        return toLabel(field.getDescribe().getName());
    }

    public rflib_SOQL toLabel(String field) {
        builder.fields.toLabel(field);
        return this;
    }

    public rflib_SOQL format(SObjectField field) {
        return format(field, '');
    }

    public rflib_SOQL format(SObjectField field, String alias) {
        builder.fields.format(field, alias);
        return this;
    }

    public rflib_SOQL delegatedScope() {
        builder.scope.delegated();
        return this;
    }

    public rflib_SOQL mineScope() {
        builder.scope.mine();
        return this;
    }

    public rflib_SOQL mineAndMyGroupsScope() {
        builder.scope.mineAndMyGroups();
        return this;
    }

    public rflib_SOQL myTerritoryScope() {
        builder.scope.myTerritory();
        return this;
    }

    public rflib_SOQL myTeamTerritoryScope() {
        builder.scope.myTeamTerritory();
        return this;
    }

    public rflib_SOQL teamScope() {
        builder.scope.team();
        return this;
    }

    public rflib_SOQL whereAre(FilterGroup filterGroup) {
        builder.conditions.add(filterGroup);
        return this;
    }

    public rflib_SOQL whereAre(Filter filter) {
        builder.conditions.add(filter);
        return this;
    }

    public rflib_SOQL whereAre(String conditions) {
        builder.conditions.add(conditions);
        return this;
    }

    public rflib_SOQL conditionLogic(String conditionLogic) {
        builder.conditions.conditionLogic(conditionLogic);
        return this;
    }

    public rflib_SOQL anyConditionMatching() {
        builder.conditions.anyConditionMatching();
        return this;
    }

    public rflib_SOQL groupBy(SObjectField field) {
        builder.groupBy.with(field);
        builder.fields.withGroupedField(field);
        return this;
    }

    public rflib_SOQL groupBy(String relationshipName, SObjectField field) {
        builder.groupBy.with(relationshipName, field);
        builder.fields.withGroupedField(relationshipName, field);
        return this;
    }

    public rflib_SOQL groupByRollup(SObjectField field) {
        builder.groupBy.rollup(field);
        builder.fields.withGroupedField(field);
        return this;
    }

    public rflib_SOQL groupByRollup(String relationshipName, SObjectField field) {
        builder.groupBy.rollup(relationshipName, field);
        builder.fields.withGroupedField(relationshipName, field);
        return this;
    }

    public rflib_SOQL groupByCube(SObjectField field) {
        builder.groupBy.cube(field);
        builder.fields.withGroupedField(field);
        return this;
    }

    public rflib_SOQL groupByCube(String relationshipName, SObjectField field) {
        builder.groupBy.cube(relationshipName, field);
        builder.fields.withGroupedField(relationshipName, field);
        return this;
    }

    public rflib_SOQL have(HavingFilterGroup havingFilterGroup) {
        builder.havingClause.add(havingFilterGroup);
        return this;
    }

    public rflib_SOQL have(HavingFilter havingFilter) {
        builder.havingClause.add(havingFilter);
        return this;
    }

    public rflib_SOQL have(String havingConditions) {
        builder.havingClause.add(havingConditions);
        return this;
    }

    public rflib_SOQL havingConditionLogic(String havingConditionsOrder) {
        builder.havingClause.conditionLogic(havingConditionsOrder);
        return this;
    }

    public rflib_SOQL anyHavingConditionMatching() {
        builder.havingClause.anyConditionMatching();
        return this;
    }

    public rflib_SOQL orderBy(String field) {
        builder.orderBys.newOrderBy().with(field);
        return this;
    }

    public rflib_SOQL orderBy(String field, String direction) {
        builder.orderBys.newOrderBy().with(field).sortingOrder(direction);
        return this;
    }

    public rflib_SOQL orderBy(SObjectField field) {
        builder.orderBys.newOrderBy().with(field);
        return this;
    }

    public rflib_SOQL orderBy(String relationshipName, SObjectField field) {
        builder.orderBys.newOrderBy().with(relationshipName, field);
        return this;
    }

    public rflib_SOQL sortDesc() {
        builder.latestOrderBy.sortDesc();
        return this;
    }

    public rflib_SOQL nullsLast() {
        builder.latestOrderBy.nullsLast();
        return this;
    }

    public rflib_SOQL setLimit(Integer amount) {
        builder.soqlLimit.max(amount);
        return this;
    }

    public rflib_SOQL offset(Integer startingRow) {
        builder.soqlOffset.offset(startingRow);
        return this;
    }

    public rflib_SOQL forReference() {
        builder.soqlFor.forReference();
        return this;
    }

    public rflib_SOQL forView() {
        builder.soqlFor.forView();
        return this;
    }

    public rflib_SOQL forUpdate() {
        builder.soqlFor.forUpdate();
        return this;
    }

    public rflib_SOQL allRows() {
        builder.soqlFor.allRows();
        return this;
    }

    public rflib_SOQL userMode() {
        executor.userMode();
        return this;
    }

    public rflib_SOQL systemMode() {
        executor.systemMode();
        return this;
    }

    public rflib_SOQL stripInaccessible() {
        return stripInaccessible(AccessType.READABLE);
    }

    public rflib_SOQL stripInaccessible(AccessType accessType) {
        executor.stripInaccessible(accessType);
        return this;
    }

    public rflib_SOQL withSharing() {
        executor.withSharing();
        return this;
    }

    public rflib_SOQL withoutSharing() {
        executor.withoutSharing();
        return this;
    }

    public rflib_SOQL mockId(String queryIdentifier) {
        executor.mockId(queryIdentifier);
        return this;
    }

    public rflib_SOQL preview() {
        System.debug(LoggingLevel.ERROR, '\n\n============ rflib_SOQL Preview ============\n' + toString() + '\n=======================================\n');
        System.debug(LoggingLevel.ERROR, '\n\n============ rflib_SOQL Binding ============\n' + JSON.serializePretty(binding()) + '\n=======================================\n');
        return this;
    }

    @TestVisible
    private Map<String, Object> binding() {
        return binder.getBindingMap();
    }

    public Id toId() {
        builder.fields.clearAllFields(); // other fields not needed
        return toObject()?.Id;
    }

    public Boolean doExist() {
        builder.fields.clearAllFields(); // other fields not needed
        return toList().size() > 0;
    }

    public override String toString() {
        binder = new Binder(); // clear binding before query build
        return builder.toString();
    }

    public Object toValueOf(SObjectField fieldToExtract) {
        builder.fields.clearAllFields(); // other fields not needed
        return with(fieldToExtract).toObject()?.get(fieldToExtract);
    }

    public Set<String> toValuesOf(SObjectField fieldToExtract) {
        // https://salesforce.stackexchange.com/questions/393308/get-a-list-of-one-column-from-a-soql-result
        builder.fields.clearAllFields(); // other fields not needed
        return new Map<String, SObject>(with(fieldToExtract, 'Id')
            .whereAre(Filter.with(fieldToExtract).isNotNull())
            .groupBy(fieldToExtract).toAggregated())
            .keySet();
    }

    public Integer toInteger() {
        builder.fields.addCountWhenNotPresented();
        return executor.toInteger();
    }

    public SObject toObject() {
        return executor.toObject();
    }

    public List<SObject> toList() {
        return executor.toList();
    }

    public List<AggregateResult> toAggregated() {
        return (List<AggregateResult>) toList();
    }

    public Map<Id, SObject> toMap() {
        return executor.toMap();
    }

    public Map<String, SObject> toMap(SObjectField keyField) {
        with(keyField);
        return executor.toMap(keyField);
    }

    public Map<String, String> toMap(SObjectField keyField, SObjectField valueField) {
        builder.fields.clearAllFields(); // other fields not needed
        with(keyField, valueField);
        return executor.toMap(keyField, valueField);
    }

    public Map<String, List<SObject>> toAggregatedMap(SObjectField keyField) {
        with(keyField);
        return executor.toAggregatedMap(keyField);
    }

    public Map<String, List<String>> toAggregatedMap(SObjectField keyField, SObjectField valueField) {
        builder.fields.clearAllFields(); // other fields not needed
        with(keyField, valueField);
        return executor.toAggregatedMap(keyField, valueField);
    }

    public Database.QueryLocator toQueryLocator() {
        return executor.toQueryLocator();
    }

    public rflib_SOQL byId(SObject record) {
        return byId(record.Id);
    }

    public rflib_SOQL byId(Id recordId) {
        return whereAre(Filter.id().equal(recordId));
    }

    public rflib_SOQL byIds(Iterable<Id> recordIds) {
        return whereAre(Filter.id().isIn(recordIds));
    }

    public rflib_SOQL byIds(List<SObject> records) {
        return whereAre(Filter.id().isIn(records));
    }

    public rflib_SOQL byRecordType(String recordTypeDeveloperName) {
        return whereAre(Filter.recordType().equal(recordTypeDeveloperName));
    }

    private interface QueryClause {
        String toString();
    }

    private class SoqlBuilder implements QueryClause {
        private List<QueryClause> clauses = new QueryClause[11];

        public SoqlBuilder(String ofObject) {
            clauses.set(0, new SoqlFields(ofObject));
            clauses.set(2, new SoqlFrom(ofObject));
        }

        public SoqlFields fields {
            get { return (SoqlFields) clauses[0]; }
        }

        public SoqlSubQueries subQueries {
            get { return (SoqlSubQueries) getQueryClause(1, SoqlSubQueries.class); }
        }

        public SoqlScope scope {
            get { return (SoqlScope) getQueryClause(3, SoqlScope.class); }
        }

        public MainFilterGroup conditions {
            get { return (MainFilterGroup) getQueryClause(4, MainFilterGroup.class); }
        }

        public SoqlGroupBy groupBy {
            get { return (SoqlGroupBy) getQueryClause(5, SoqlGroupBy.class); }
        }

        public MainHavingGroup havingClause {
            get { return (MainHavingGroup) getQueryClause(6, MainHavingGroup.class); }
        }

        public SoqlOrderBy latestOrderBy {
            get { return orderBys.latestOrderBy(); }
        }

        public SoqlOrderBys orderBys {
            get { return (SoqlOrderBys) getQueryClause(7, SoqlOrderBys.class); }
        }

        public SoqlLimit soqlLimit {
            get { return (SoqlLimit) getQueryClause(8, SoqlLimit.class); }
        }

        public SoqlOffset soqlOffset {
            get { return (SoqlOffset) getQueryClause(9, SoqlOffset.class); }
        }

        public SoqlFor soqlFor {
            get { return (SoqlFor) getQueryClause(10, SoqlFor.class); }
        }

        private QueryClause getQueryClause(Integer position, System.Type queryClause) {
            if (clauses[position] == null) {
                clauses.set(position, (QueryClause) queryClause.newInstance());
            }
            return clauses[position];
        }

        public override String toString() {
            String query = '';

            for (QueryClause clause : clauses) {
                if (clause != null) {
                    query += ' ' + clause.toString();
                }
            }

            return query.trim();
        }
    }

    private class SoqlFields implements QueryClause {
        private String ofObject;
        private Set<String> fields = new Set<String>();
        private Set<String> aggregateFunctions = new Set<String>();
        private Set<String> groupedFields = new Set<String>();

        public SoqlFields(String ofObject) {
            this.ofObject = ofObject;
        }

        public void count() {
            clearAllFields(); // COUNT() must be the only element in the SELECT list.
            withAggregateFunction('COUNT()', '');
        }

        public void count(SObjectField field, String alias) {
            with('COUNT', field, alias);
        }

        public void count(String relationshipName, SObjectField field, String alias) {
            with('COUNT', relationshipName, field, alias);
        }

        public void avg(SObjectField field, String alias) {
            with('AVG', field, alias);
        }

        public void avg(String relationshipName, SObjectField field, String alias) {
            with('AVG', relationshipName, field, alias);
        }

        public void countDistinct(SObjectField field, String alias) {
            with('COUNT_DISTINCT', field, alias);
        }

        public void countDistinct(String relationshipName, SObjectField field, String alias) {
            with('COUNT_DISTINCT', relationshipName, field, alias);
        }

        public void min(SObjectField field, String alias) {
            with('MIN', field, alias);
        }

        public void min(String relationshipName, SObjectField field, String alias) {
            with('MIN', relationshipName, field, alias);
        }

        public void max(SObjectField field, String alias) {
            with('MAX', field, alias);
        }

        public void max(String relationshipName, SObjectField field, String alias) {
            with('MAX', relationshipName, field, alias);
        }

        public void sum(SObjectField field, String alias) {
            with('SUM', field, alias);
        }

        public void sum(String relationshipName, SObjectField field, String alias) {
            with('SUM', relationshipName, field, alias);
        }

        public void grouping(SObjectField field, String alias) {
            with('GROUPING', field, alias);
        }

        public void with(String function, String relationshipName, SObjectField field, String alias) {
            withAggregateFunction(function + '(' + relationshipName + '.' + field + ')', alias);
        }

        public void with(String function, SObjectField field, String alias) {
            withAggregateFunction(function + '(' + field + ')', alias);
        }

        public void with(SObjectField field, String alias) {
            withAggregateFunction(field.getDescribe().getName(), alias);
        }

        private void withAggregateFunction(String aggregateFunction, String alias) {
            if (String.isNotBlank(alias)) {
                aggregateFunction += ' ' + alias;
            }

            aggregateFunctions.add(aggregateFunction);
        }

        public void withGroupedField(SObjectField field) {
            groupedFields.add(field.getDescribe().getName());
        }

        public void withGroupedField(String relationshipName, SObjectField field) {
            groupedFields.add(relationshipName + '.' + field);
        }

        public void with(String commaSeparatedFields) {
            // Added to Set to avoid field duplicates in query
            for (String splittedField : commaSeparatedFields.split(',')) {
                String field = splittedField.trim();
                if (isAggregateFunction(field)) {
                    aggregateFunctions.add(field);
                } else {
                    fields.add(field);
                }
            }
        }

        private Boolean isAggregateFunction(String field) {
            // AVG(), COUNT(), MIN(), MAX(), SUM() or Field aliasing
            return field.contains('(') && field.contains(')') || field.contains(' ');
        }

        public void with(Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                with(field);
            }
        }

        public void withFieldSet(String fieldSetName) {
            FieldSet fieldSet = Schema.describeSObjects(new List<String>{ ofObject })[0].FieldSets.getMap().get(fieldSetName);

            if (fieldSet == null) {
                throw new QueryException('FieldSet with name ' + fieldSetName + ' does not exist!');
            }

            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                with(field.getFieldPath());
            }
        }

        public void with(SObjectField field) {
            fields.add(field.getDescribe().getName());
        }

        public void toLabel(String field) {
            fields.add('toLabel(' + field + ')');
        }

        private void format(SObjectField field, String alias) {
            fields.add('FORMAT(' + field + ') ' + alias);
        }

        public void with(String relationshipPath, Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                with(relationshipPath, field);
            }
        }

        public void with(String relationshipPath, SObjectField field) {
            fields.add(relationshipPath + '.' + field);
        }

        public void clearAllFields() {
            fields.clear();
            aggregateFunctions.clear();
        }

        public void addCountWhenNotPresented() {
            if (aggregateFunctions.isEmpty()) {
                count();
            }
        }

        public override String toString() {
            if (fields.isEmpty() && aggregateFunctions.isEmpty()) {
                return 'SELECT Id';
            }

            if (!groupedFields.isEmpty() || !aggregateFunctions.isEmpty()) {
                List<String> selectFields = new List<String>();

                // To avoid "Field must be grouped or aggregated" error
                // retain only grouped or aggregated fields
                fields.retainAll(groupedFields);

                selectFields.addAll(fields);
                selectFields.addAll(aggregateFunctions);

                return 'SELECT ' + String.join(selectFields, ', ');
            }

            return 'SELECT ' + String.join(fields, ', ');
        }
    }

    private class SoqlSubQuery implements SubQuery {
        private SoqlBuilder builder;

        public SubQuery of(String ofObject) {
            builder = new SoqlBuilder(ofObject);
            return this;
        }

        public SubQuery with(SObjectField field) {
            builder.fields.with(field);
            return this;
        }

        public SubQuery with(SObjectField field1, SObjectField field2) {
            return with(field1).with(field2);
        }

        public SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3) {
            return with(field1, field2).with(field3);
        }

        public SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            return with(field1, field2, field3).with(field4);
        }

        public SubQuery with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            return with(field1, field2, field3, field4).with(field5);
        }

        public SubQuery with(Iterable<SObjectField> fields) {
            builder.fields.with(fields);
            return this;
        }

        public SubQuery with(String relationshipName, Iterable<SObjectField> fields) {
            builder.fields.with(relationshipName, fields);
            return this;
        }

        public SubQuery with(SubQuery subQuery) {
            builder.subQueries.add(subQuery);
            return this;
        }

        public SubQuery whereAre(FilterGroup filterGroup) {
            builder.conditions.add(filterGroup);
            return this;
        }

        public SubQuery whereAre(Filter filter) {
            builder.conditions.add(filter);
            return this;
        }

        public SubQuery orderBy(SObjectField field) {
            builder.orderBys.newOrderBy().with(field);
            return this;
        }

        public SubQuery orderBy(String relationshipName, SObjectField field) {
            builder.orderBys.newOrderBy().with(relationshipName, field);
            return this;
        }

        public SubQuery sortDesc() {
            builder.latestOrderBy.sortDesc();
            return this;
        }

        public SubQuery nullsLast() {
            builder.latestOrderBy.nullsLast();
            return this;
        }

        public SubQuery setLimit(Integer amount) {
            builder.soqlLimit.max(amount);
            return this;
        }

        public SubQuery offset(Integer startingRow) {
            builder.soqlOffset.offset(startingRow);
            return this;
        }

        public SubQuery forReference() {
            builder.soqlFor.forReference();
            return this;
        }

        public SubQuery forView() {
            builder.soqlFor.forView();
            return this;
        }

        public override String toString() {
            return builder.toString();
        }
    }

    private class SoqlSubQueries implements QueryClause {
        private List<SubQuery> subQueries = new List<SubQuery>();

        public void add(SubQuery subQuery) {
            subQueries.add(subQuery);
        }

        public override String toString() {
            List<String> subQueriesStrings = new List<String>();

            for (SubQuery sub : subQueries) {
                subQueriesStrings.add('(' + sub + ')');
            }

            return ', ' + String.join(subQueriesStrings, ', ');
        }
    }

    private class SoqlFrom implements QueryClause {
        private String objectApiName;

        public SoqlFrom(String objectType) {
            objectApiName = objectType;
        }

        public override String toString() {
            return 'FROM ' + objectApiName;
        }
    }

    private class SoqlScope implements QueryClause {
        private String scope = 'EVERYTHING';

        public void delegated() {
            scope = 'DELEGATED';
        }

        public void mine() {
            scope = 'MINE';
        }

        public void mineAndMyGroups() {
            scope = 'MINE_AND_MY_GROUPS';
        }

        public void myTerritory() {
            scope = 'MY_TERRITORY';
        }

        public void myTeamTerritory() {
            scope = 'MY_TEAM_TERRITORY';
        }

        public void team() {
            scope = 'TEAM';
        }

        public override String toString() {
            return 'USING SCOPE ' + scope;
        }
    }

    private interface FilterClause {
        String toString();
        Boolean hasValue();
    }

    private virtual class SoqlFilterGroup implements FilterGroup {
        private List<FilterClause> queryConditions = new List<FilterClause>();
        private String customOrder;
        private String connector = 'AND';

        public FilterGroup add(FilterGroup filterGroup) {
            return add(new FilterGroupAdapter(filterGroup));
        }

        public FilterGroup add(Filter filter) {
            return add(new FilterAdapter(filter));
        }

        public FilterGroup add(String dynamicCondition) {
            return add(new StringConditionAdapter(dynamicCondition));
        }

        public FilterGroup add(FilterClause condition) {
            if (condition.hasValue()) {
                queryConditions.add(condition);
            }
            return this;
        }

        public FilterGroup anyConditionMatching() {
            connector = 'OR';
            return this;
        }

        public FilterGroup conditionLogic(String order) {
            customOrder = order;
            return this;
        }

        public FilterGroup ignoreWhen(Boolean logicExpression) {
            if (logicExpression) {
                queryConditions = new List<FilterClause>();
            }
            return this;
        }

        public Boolean hasValues() {
            return !queryConditions.isEmpty();
        }

        public virtual override String toString() {
            return '(' + buildNested() + ')';
        }

        public String buildNested() {
            return String.format(getOrderWithSpecialCharacters(), queryConditions);
        }

        private String getOrderWithSpecialCharacters() {
            String orderWithSpecialCharacters = getConditionsLogic();

            for (Integer i = 0; i < queryConditions.size(); i++) {
                orderWithSpecialCharacters = orderWithSpecialCharacters.replaceAll('\\b' + String.valueOf(i + 1) + '\\b', '{' + i + '}');
            }

            return orderWithSpecialCharacters; // e.g ({0} AND ({1} AND {2}))
        }

        private String getConditionsLogic() {
            if (String.isNotEmpty(customOrder)) {
                return customOrder;
            }

            List<String> defaultOrder = new List<String>();

            for (Integer i = 0; i < queryConditions.size(); i++) {
                defaultOrder.add(String.valueOf(i + 1));
            }

            return String.join(defaultOrder, ' ' + connector + ' '); // e.g (0 AND 1 AND 2)
        }
    }

    private class MainFilterGroup extends SoqlFilterGroup implements QueryClause {
        public override String toString() {
            if (!hasValues()) {
                return '';
            }

            return 'WHERE ' + buildNested();
        }
    }

    private class FilterGroupAdapter implements FilterClause {
        private FilterGroup filterGroup;

        public FilterGroupAdapter(FilterGroup filterGroup) {
            this.filterGroup = filterGroup;
        }

        public Boolean hasValue() {
            return filterGroup.hasValues();
        }

        public override String toString() {
            return filterGroup.toString();
        }
    }

    private class FilterAdapter implements FilterClause {
        private Filter filter;

        public FilterAdapter(Filter filter) {
            this.filter = filter;
        }

        public Boolean hasValue() {
            return filter.hasValue();
        }

        public override String toString() {
            return filter.toString();
        }
    }

    private class StringConditionAdapter implements FilterClause {
        private String conditionString;

        public StringConditionAdapter(String dynamicCondition) {
            conditionString = dynamicCondition;
        }

        public Boolean hasValue() {
            return String.isNotEmpty(conditionString);
        }

        public override String toString() {
            return conditionString;
        }
    }

    private class SoqlFilter implements Filter {
        private String field;
        private String comperator;
        private Object value;
        private String wrapper = '{0}';
        private Boolean skipBinding = false;

        public Filter id() {
            return with('Id');
        }

        public Filter recordType() {
            return with('RecordType.DeveloperName');
        }

        public Filter name() {
            return with('Name');
        }

        public Filter with(SObjectField field) {
            return with(field.getDescribe().getName());
        }

        public Filter with(String relationshipName, SObjectField field) {
            return with(relationshipName + '.' + field);
        }

        public Filter with(String field) {
            this.field = field;
            return this;
        }

        public Filter isNull() {
            return equal(null);
        }

        public Filter isNotNull() {
            return notEqual(null);
        }

        public Filter isTrue() {
            return equal(true);
        }

        public Filter isFalse() {
            return equal(false);
        }

        public Filter equal(Object value) {
            return set('=', value);
        }

        public Filter notEqual(Object value) {
            return set('!=', value);
        }

        public Filter lessThan(Object value) {
            return set('<', value);
        }

        public Filter greaterThan(Object value) {
            return set('>', value);
        }

        public Filter lessOrEqual(Object value) {
            return set('<=', value);
        }

        public Filter greaterOrEqual(Object value) {
            return set('>=', value);
        }

        public Filter containsSome(Iterable<String> values) {
            return set('LIKE', values);
        }

        public Filter contains(String value) {
            return contains('%', formattedString(value), '%');
        }

        public Filter notContains(String value) {
            return notLike().contains(value);
        }

        public Filter endsWith(String value) {
            return contains('%', formattedString(value), '');
        }

        public Filter notEndsWith(String value) {
            return notLike().endsWith(value);
        }

        public Filter startsWith(String value) {
            return contains('', formattedString(value), '%');
        }

        public Filter notStartsWith(String value) {
            return notLike().startsWith(value);
        }

        public Filter contains(String prefix, String value, String suffix) {
            return set('LIKE', prefix + formattedString(value) + suffix);
        }

        public Filter notContains(String prefix, String value, String suffix) {
            return notLike().contains(prefix, value, suffix);
        }

        private String formattedString(String value) {
            return value ?? value?.trim();
        }

        public Filter isIn(Iterable<Object> iterable) {
            return set('IN', iterable);
        }

        public Filter isIn(InnerJoin joinQuery) {
            skipBinding = true;
            return set('IN', joinQuery);
        }

        private Filter notLike() {
            this.wrapper = '(NOT {0})';
            return this;
        }

        public Filter notIn(Iterable<Object> iterable) {
            return set('NOT IN', iterable);
        }

        public Filter notIn(InnerJoin joinQuery) {
            skipBinding = true;
            return set('NOT IN', joinQuery);
        }

        public Filter includesAll(Iterable<String> iterable) {
            return setMultipicklistFilter('INCLUDES', iterable, ';');
        }

        public Filter includesSome(Iterable<String> iterable) {
            return setMultipicklistFilter('INCLUDES', iterable, '\', \'');
        }

        public Filter excludesAll(Iterable<String> iterable) {
            return setMultipicklistFilter('EXCLUDES', iterable, '\', \'');
        }

        public Filter excludesSome(Iterable<String> iterable) {
            return setMultipicklistFilter('EXCLUDES', iterable, ';');
        }

        public Filter setMultipicklistFilter(String operator, Iterable<String> iterable, String separator) {
             // Bind expressions can't be used with other clauses, such as INCLUDES, EXCLUDES
             skipBinding = true;
             return set(operator, '(\'' + String.join(iterable, separator) + '\')');
        }

        private Filter set(String comperator, Object value) {
            this.value = value;
            this.comperator = comperator;
            return this;
        }

        public Boolean hasValue() {
            return String.isNotEmpty(field);
        }

        public Filter ignoreWhen(Boolean logicExpression) {
            if (logicExpression) {
                // Set field as empty to meet hasValue and ignore condition
                with('');
            }
            return this;
        }

        public Filter asDateLiteral() {
            // Date Literals can't be binded
            skipBinding = true;
            return this;
        }

        public override String toString() {
            if (skipBinding) {
                return String.format(wrapper, new List<String>{ field + ' ' + comperator + ' ' + value });
            }

            return String.format(wrapper, new List<String>{ field + ' ' + comperator + ' :' + binder.bind(value) });
        }
    }

    private class SoqlJoinQuery implements InnerJoin {
        private SoqlBuilder builder;

        public InnerJoin of(SObjectType ofObject) {
            builder = new SoqlBuilder(ofObject.getDescribe().getName());
            return this;
        }

        public InnerJoin with(SObjectField field) {
            builder.fields.with(field);
            return this;
        }

        public InnerJoin whereAre(FilterGroup filterGroup) {
            builder.conditions.add(filterGroup);
            return this;
        }

        public InnerJoin whereAre(Filter filter) {
            builder.conditions.add(filter);
            return this;
        }

        public override String toString() {
            return '(' + builder.toString() + ')';
        }
    }

    private class SoqlGroupBy implements QueryClause {
        private Set<String> groupByFields = new Set<String>();
        private String groupByFunction = '';

        public void with(SObjectField field) {
            with(field.getDescribe().getName());
        }

        public void with(String relationshipName, SObjectField field) {
            with(relationshipName + '.' + field);
        }

        private void with(String field) {
            setGroupByFunction('{0}');
            groupByFields.add(field.trim());
        }

        public void rollup(SObjectField field) {
            rollup(field.getDescribe().getName());
        }

        public void rollup(String relationshipName, SObjectField field) {
            rollup(relationshipName + '.' + field);
        }

        private void rollup(String field) {
            setGroupByFunction('ROLLUP({0})');
            groupByFields.add(field.trim());
        }

        public void cube(SObjectField field) {
            cube(field.getDescribe().getName());
        }

        public void cube(String relationshipName, SObjectField field) {
            cube(relationshipName + '.' + field);
        }

        private void cube(String field) {
            setGroupByFunction('CUBE({0})');
            groupByFields.add(field.trim());
        }

        public void setGroupByFunction(String newGroupByFunction) {
            if (String.isNotEmpty(groupByFunction) && groupByFunction != newGroupByFunction) {
                throw new QueryException('You can\'t use GROUP BY, GROUP BY ROLLUP and GROUP BY CUBE in the same query.');
            }
            this.groupByFunction = newGroupByFunction;
        }

        public override String toString() {
            return 'GROUP BY ' + String.format(groupByFunction, new List<String>{ String.join(groupByFields, ', ') });
        }
    }

    private class SoqlOrderBys implements QueryClause {
        public List<SoqlOrderBy> orderBys = new List<SoqlOrderBy>();

        public SoqlOrderBy newOrderBy() {
            orderBys.add(new SoqlOrderBy());
            return latestOrderBy();
        }

        public SoqlOrderBy latestOrderBy() {
            return orderBys.get(orderBys.size() - 1);
        }

        public override String toString() {
            List<String> orderFields = new List<String>();

            for (SoqlOrderBy orderBy : orderBys) {
                orderFields.add(orderBy.toString());
            }

            return 'ORDER BY ' + String.join(orderFields, ', ');
        }
    }

    private virtual class SoqlHavingFilterGroup implements HavingFilterGroup, HavingFilterClause {
        private List<HavingFilterClause> havingConditions = new List<HavingFilterClause>();
        private String customOrder;
        private String connector = 'AND';

        public HavingFilterGroup add(HavingFilterGroup filterGroup) {
            return add(new HavingFilterGroupAdapter(filterGroup));
        }

        public HavingFilterGroup add(HavingFilter filter) {
            return add(new HavingFilterAdapter(filter));
        }

        public HavingFilterGroup add(String filter) {
            return add(new HavingStringAdapter(filter));
        }

        public HavingFilterGroup add(HavingFilterClause condition) {
            havingConditions.add(condition);
            return this;
        }

        public HavingFilterGroup anyConditionMatching() {
            connector = 'OR';
            return this;
        }

        public HavingFilterGroup conditionLogic(String order) {
            customOrder = order;
            return this;
        }

        public virtual override String toString() {
            return '(' + buildNested() + ')';
        }

        public String buildNested() {
            return String.format(getOrderWithSpecialCharacters(), havingConditions);
        }

        private String getOrderWithSpecialCharacters() {
            String orderWithSpecialCharacters = getConditionsLogic();

            for (Integer i = 0; i < havingConditions.size(); i++) {
                orderWithSpecialCharacters = orderWithSpecialCharacters.replaceFirst(String.valueOf(i + 1), '{' + i + '}');
            }

            return orderWithSpecialCharacters; // e.g ({0} AND ({1} AND {2}))
        }

        private String getConditionsLogic() {
            if (String.isNotEmpty(customOrder)) {
                return customOrder;
            }

            List<String> defaultOrder = new List<String>();

            for (Integer i = 0; i < havingConditions.size(); i++) {
                defaultOrder.add(String.valueOf(i + 1));
            }

            return String.join(defaultOrder, ' ' + connector + ' '); // e.g (0 AND 1 AND 2)
        }
    }

    private class MainHavingGroup extends SoqlHavingFilterGroup implements QueryClause {
        public override String toString() {
            return 'HAVING ' + buildNested();
        }
    }

    private interface HavingFilterClause {
        String toString();
    }

    private class HavingFilterGroupAdapter implements HavingFilterClause {
        private HavingFilterGroup havingFilterGroup;

        public HavingFilterGroupAdapter(HavingFilterGroup havingFilterGroup) {
            this.havingFilterGroup = havingFilterGroup;
        }

        public override String toString() {
            return havingFilterGroup.toString();
        }
    }

    private class HavingFilterAdapter implements HavingFilterClause {
        private HavingFilter havingFilter;

        public HavingFilterAdapter(HavingFilter havingFilter) {
            this.havingFilter = havingFilter;
        }

        public override String toString() {
            return havingFilter.toString();
        }
    }

    private class HavingStringAdapter implements HavingFilterClause {
        private String condition;

        public HavingStringAdapter(String condition) {
            this.condition = condition;
        }

        public override String toString() {
            return condition.toString();
        }
    }

    private class SoqlHavingFilter implements HavingFilter, HavingFilterClause {
        private String field;
        private String comperator;
        private Object value;
        private String wrapper = '{0}';

        public HavingFilter with(SObjectField field) {
            return with(field.getDescribe().getName());
        }

        public HavingFilter with(String field) {
            this.field = field;
            return this;
        }

        public HavingFilter count(SObjectField field) {
            return withAggregateFunction('COUNT', field);
        }

        public HavingFilter avg(SObjectField field) {
            return withAggregateFunction('AVG', field);
        }

        public HavingFilter countDistinct(SObjectField field) {
            return withAggregateFunction('COUNT_DISTINCT', field);
        }

        public HavingFilter min(SObjectField field) {
            return withAggregateFunction('MIN', field);
        }

        public HavingFilter max(SObjectField field) {
            return withAggregateFunction('MAX', field);
        }

        public HavingFilter sum(SObjectField field) {
            return withAggregateFunction('SUM', field);
        }

        private HavingFilter withAggregateFunction(String aggregateFunction, SObjectField field) {
            return withAggregateFunction(aggregateFunction, field.getDescribe().getName());
        }

        private HavingFilter withAggregateFunction(String aggregateFunction, String field) {
            this.field = aggregateFunction + '(' + field + ')';
            return this;
        }

        public HavingFilter isNull() {
            return equal(null);
        }

        public HavingFilter isNotNull() {
            return notEqual(null);
        }

        public HavingFilter isTrue() {
            return equal(true);
        }

        public HavingFilter isFalse() {
            return equal(false);
        }

        public HavingFilter equal(Object value) {
            return set('=', value);
        }

        public HavingFilter notEqual(Object value) {
            return set('!=', value);
        }

        public HavingFilter lessThan(Object value) {
            return set('<', value);
        }

        public HavingFilter greaterThan(Object value) {
            return set('>', value);
        }

        public HavingFilter lessOrEqual(Object value) {
            return set('<=', value);
        }

        public HavingFilter greaterOrEqual(Object value) {
            return set('>=', value);
        }

        public HavingFilter contains(String value) {
            return contains('%', formattedString(value), '%');
        }

        public HavingFilter notContains(String value) {
            return notLike().contains(value);
        }

        public HavingFilter endsWith(String value) {
            return contains('%', formattedString(value), '');
        }

        public HavingFilter notEndsWith(String value) {
            return notLike().endsWith(value);
        }

        public HavingFilter startsWith(String value) {
            return contains('', formattedString(value), '%');
        }

        public HavingFilter notStartsWith(String value) {
            return notLike().startsWith(value);
        }

        public HavingFilter contains(String prefix, String value, String suffix) {
            return set('LIKE', prefix + formattedString(value) + suffix);
        }

        public HavingFilter notContains(String prefix, String value, String suffix) {
            return notLike().contains(prefix, value, suffix);
        }

        public HavingFilter isIn(Iterable<Object> iterable) {
            return set('IN', iterable, '\', \'');
        }

        public HavingFilter notIn(Iterable<Object> iterable) {
            return set('NOT IN', iterable, '\', \'');
        }

        private String formattedString(String value) {
            return value ?? value?.trim();
        }

        private HavingFilter notLike() {
            this.wrapper = '(NOT {0})';
            return this;
        }

        public HavingFilter set(String operator, Iterable<String> iterable, String separator) {
             this.comperator = operator;
             this.value = '(\'' + String.join(iterable, separator) + '\')';
             return this;
        }

        private HavingFilter set(String comperator, Object value) {
            this.comperator = comperator;
            this.value = value instanceof String ? '\'' + value + '\'' : value;
            return this;
        }

        public override String toString() {
            return String.format(wrapper, new List<String>{ field + ' ' + comperator + ' ' + value });
        }
    }

    private class SoqlOrderBy implements QueryClause {
        private String orderField;
        private String sortingOrder = 'ASC';
        private String nullsOrder = 'FIRST';

        public void with(SObjectField field) {
            with(field.getDescribe().getName());
        }

        public void with(String relationshipName, SObjectField field) {
            with(relationshipName + '.' + field);
        }

        public SoqlOrderBy with(String field) {
            orderField = field;
            return this;
        }

        public void sortDesc() {
            sortingOrder('DESC');
        }

        public void sortingOrder(String direction) {
            sortingOrder = direction;
        }

        public void nullsLast() {
            nullsOrder = 'LAST';
        }

        public override String toString() {
            return orderField + ' ' + sortingOrder + ' NULLS ' + nullsOrder;
        }
    }

    private class SoqlLimit implements QueryClause {
        private Integer soqlLimit;

        public void max(Integer soqlLimit) {
            this.soqlLimit = soqlLimit;
        }

        public override String toString() {
            return 'LIMIT ' + this.soqlLimit;
        }
    }

    private class SoqlOffset implements QueryClause {
        private Integer soqlOffset;

        public void offset(Integer fromRow) {
            soqlOffset = fromRow;
        }

        public override String toString() {
            return 'OFFSET ' + soqlOffset;
        }
    }

    private class SoqlFor implements QueryClause {
        private String forStatement;

        public void forReference() {
            forStatement = 'FOR REFERENCE';
        }

        public void forView() {
            forStatement = 'FOR VIEW';
        }

        public void forUpdate() {
            forStatement = 'FOR UPDATE';
        }

        public void allRows() {
            forStatement = 'ALL ROWS';
        }

        public override String toString() {
            return forStatement;
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

        public Map<String, Object> getBindingMap() {
            return binding;
        }
    }

    private class Mock {
        private final Map<String, List<SObject>> sObjectsMocks = new Map<String, List<SObject>>();
        private final Map<String, Integer> countMocks = new Map<String, Integer>();

        public void setMock(String mockId, List<SObject> records) {
            sObjectsMocks.put(mockId, records);
        }

        public void setCountMock(String mockId, Integer amount) {
            countMocks.put(mockId, amount);
        }

        public Boolean hasMock(String mockId) {
            return sObjectsMocks.containsKey(mockId);
        }

        public Boolean hasCountMock(String mockId) {
            return countMocks.containsKey(mockId);
        }

        public List<SObject> getSObjectsMock(String mockId) {
            return sObjectsMocks.get(mockId);
        }

        public Integer getCountMock(String mockId) {
            return countMocks.get(mockId);
        }
    }

    private inherited sharing class Executor {
        private DatabaseQuery sharingExecutor;
        private AccessLevel accessMode;
        private AccessType accessType;
        private String mockId;
        private String ofObject;
        private SoqlBuilder builder;

        public Executor(String ofObject, SoqlBuilder builder) {
            this.ofObject = ofObject;
            this.builder = builder;

            userMode();
            inheritedSharing();
        }

        public void inheritedSharing() {
            sharingExecutor = new InheritedSharing();
        }

        public void withSharing() {
            sharingExecutor = new WithSharing();
        }

        public void withoutSharing() {
            sharingExecutor = new WithoutSharing();
        }

        public void stripInaccessible(AccessType type) {
            accessType = type;
        }

        public void userMode() { // The object permissions, field-level security, sharing rules are enforced.
            accessMode = AccessLevel.USER_MODE;
        }

        public void systemMode() { // The object permissions, field-level permissions are ignored, sharing rules are controlled by the sharingMode.
            accessMode = AccessLevel.SYSTEM_MODE;
        }

        public void mockId(String id) {
            mockId = id;
        }

        public SObject toObject() {
            List<SObject> records = toList();

            if (records.size() > 1) {
                throw new QueryException('List has more than 1 row for assignment to SObject');
            }

            if (records.size() == 0) {
                return null; // handle: List has no rows for assignment to SObject
            }

            return records[0];
        }

        public List<SObject> toList() {
            if (mock.hasMock(mockId)) {
                return mock.getSObjectsMock(mockId);
            }

            if (accessType == null) {
                return sharingExecutor.toSObjects(builder.toString(), binder.getBindingMap(), accessMode);
            }

            return Security.stripInaccessible(
                accessType,
                sharingExecutor.toSObjects(builder.toString(), binder.getBindingMap(), accessMode)
            ).getRecords();
        }

        public Map<Id, SObject> toMap() {
            Map<Id, SObject> recordPerId = (Map<Id, SObject>) Type.forName('Map<Id, ' + ofObject  + ' >').newInstance();
            recordPerId.putAll(toList());
            return recordPerId;
        }

        public Map<String, SObject> toMap(SObjectField keyField) {
            Map<String, SObject> recordPerCustomKey = (Map<String, SObject>) Type.forName('Map<String, ' + ofObject  + ' >').newInstance();

            for (SObject record : toList()) {
                recordPerCustomKey.put(String.valueOf(record.get(keyField)), record);
            }

            return recordPerCustomKey;
        }

        public Map<String, String> toMap(SObjectField keyField, SObjectField valueField) {
            Map<String, String> customValuePerCustomKey = new Map<String, String>();

            for (SObject record : toList()) {
                customValuePerCustomKey.put(String.valueOf(record.get(keyField)), String.valueOf(record.get(valueField)));
            }

            return customValuePerCustomKey;
        }

        public Map<String, List<SObject>> toAggregatedMap(SObjectField keyField) {
            Map<String, List<SObject>> recordsPerCustomKey = (Map<String, List<SObject>>) Type.forName('Map<String, List<' + ofObject  + ' >>').newInstance();

            for (SObject record : toList()) {
                String key = String.valueOf(record.get(keyField));

                if (!recordsPerCustomKey.containsKey(key)) {
                    recordsPerCustomKey.put(key, new List<SObject>());
                }

                recordsPerCustomKey.get(key).add(record);
            }

            return recordsPerCustomKey;
        }

        public Map<String, List<String>> toAggregatedMap(SObjectField keyField, SObjectField valueField) {
            Map<String, List<String>> customValuesPerCustomKey = new Map<String, List<String>>();

            for (SObject record : toList()) {
                String key = String.valueOf(record.get(keyField));

                if (!customValuesPerCustomKey.containsKey(key)) {
                    customValuesPerCustomKey.put(key, new List<String>());
                }

                customValuesPerCustomKey.get(key).add(String.valueOf(record.get(valueField)));
            }

            return customValuesPerCustomKey;
        }

        public Integer toInteger() {
            if (mock.hasCountMock(mockId)) {
                return mock.getCountMock(mockId);
            }

            return sharingExecutor.toInteger(builder.toString(), binder.getBindingMap(), accessMode);
        }

        public Database.QueryLocator toQueryLocator() {
            return sharingExecutor.toQueryLocator(builder.toString(), binder.getBindingMap(), accessMode);
        }
    }

    private interface DatabaseQuery {
        List<SObject> toSObjects(String query, Map<String, Object> binding, AccessLevel accessLevel);
        Integer toInteger(String query, Map<String, Object> binding, AccessLevel accessLevel);
        Database.QueryLocator toQueryLocator(String query, Map<String, Object> binding, AccessLevel accessLevel);
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
    }
}
