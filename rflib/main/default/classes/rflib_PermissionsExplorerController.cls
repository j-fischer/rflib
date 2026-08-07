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
public with sharing class rflib_PermissionsExplorerController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_PermissionsExplorerController');

    private static final String FLS_SEARCH_TYPE = 'FLS';
    private static final String OBJ_SEARCH_TYPE = 'OBJ';
    private static final String APEX_SEARCH_TYPE = 'APX';
    
    @TestVisible private static final Integer APEX_CURSOR_RESULT_SIZE = 2000;
    @TestVisible private static final Integer APEX_QUERY_RECORD_LIMIT = 24995;

    // Schema.describeSObjects() accepts at most 100 objects per call, and that API cap is the real
    // constraint: describe results come from the platform's describe cache rather than the
    // transaction heap, so 23 of the widest standard objects (673 fields without FLS) measured at only
    // 29 KB - about 1% of the 6 MB heap.
    @TestVisible private static final Integer MAX_DESCRIBE_BATCH_SIZE = 100;

    // Insurance rather than a routine limit: measured usage is nowhere near the heap, but an org
    // with pathologically wide objects should get a real error instead of an uncatchable heap
    // LimitException. Mutable so a test can lower it far enough to exercise the guard.
    @TestVisible private static Decimal describeHeapSafetyRatio = 0.6;
    
    @TestVisible private static final String COUNT = 'SELECT COUNT()';
    @TestVisible private static final String FLS_FIELDS = 'SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, Parent.PermissionSetGroupId, SobjectType, Field, PermissionsEdit, PermissionsRead';
    @TestVisible private static final String OBJ_FIELDS = 'SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, Parent.PermissionSetGroupId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllFields, PermissionsViewAllRecords, PermissionsModifyAllRecords';
    @TestVisible private static final String APEX_FIELDS = 'SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, Parent.PermissionSetGroupId, SetupEntityType, SetupEntityId';
 
    @TestVisible private static final String FLS_TABLE = ' FROM FieldPermissions';
    @TestVisible private static final String OBJ_TABLE = ' FROM ObjectPermissions';
    @TestVisible private static final String APEX_TABLE = ' FROM SetupEntityAccess';

    @TestVisible private static final String PROFILE_QUERY_CONDITION = ' WHERE Parent.IsOwnedByProfile = true';
    @TestVisible private static final String PERMISSION_SET_QUERY_CONDITION = ' WHERE Parent.IsOwnedByProfile = false AND Parent.PermissionSetGroupId = null';
    @TestVisible private static final String PERMISSION_SET_GROUP_QUERY_CONDITION = ' WHERE Parent.IsOwnedByProfile = false AND Parent.PermissionSetGroupId != null';
    @TestVisible private static final String USER_QUERY_CONDITION = ' WHERE (Parent.ProfileId = {0} OR ParentId IN {1})';

    @TestVisible private static final String APEX_CONDITIONS = ' AND (SetupEntityType = \'ApexClass\' OR SetupEntityType = \'ApexPage\')';
 
    @TestVisible private static final String FLS_ORDER = ' ORDER BY Parent.Profile.Name, Parent.Label, SobjectType, Field'; 
    @TestVisible private static final String OBJ_ORDER = ' ORDER BY Parent.Profile.Name, Parent.Label, SobjectType'; 
    @TestVisible private static final String APEX_ORDER = ' ORDER BY Parent.Profile.Name, Parent.Label'; 

    @TestVisible private static rflib_QueryExecutor queryExecutor  = new rflib_DatabaseQueryExecutor();

    @AuraEnabled(cacheable = true)
    public static QueryResult getFieldLevelSecurityForAllProfiles(String servicePath, Integer position){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getFieldLevelSecurityForAllProfiles: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, FLS_SEARCH_TYPE, PROFILE_QUERY_CONDITION) : 
                queryPermissionsApex(FLS_SEARCH_TYPE, PROFILE_QUERY_CONDITION, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all profiles', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getFieldLevelSecurityForAllPermissionSets(String servicePath, Integer position) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getFieldLevelSecurityForAllPermissionSets: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, FLS_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION) : 
                queryPermissionsApex(FLS_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static QueryResult getFieldLevelSecurityForAllPermissionSetGroups(String servicePath, Integer position) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getFieldLevelSecurityForAllPermissionSets: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, FLS_SEARCH_TYPE, PERMISSION_SET_GROUP_QUERY_CONDITION) : 
                queryPermissionsApex(FLS_SEARCH_TYPE, PERMISSION_SET_GROUP_QUERY_CONDITION, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getObjectLevelSecurityForAllProfiles(String servicePath, Integer position){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getObjectLevelSecurityForAllProfiles: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, OBJ_SEARCH_TYPE, PROFILE_QUERY_CONDITION) : 
                queryPermissionsApex(OBJ_SEARCH_TYPE, PROFILE_QUERY_CONDITION, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all profiles', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getObjectLevelSecurityForAllPermissionSets(String servicePath, Integer position){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getObjectLevelSecurityForAllPermissionSets: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, OBJ_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION) : 
                queryPermissionsApex(OBJ_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static QueryResult getObjectLevelSecurityForAllPermissionSetGroups(String servicePath, Integer position){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getObjectLevelSecurityForAllPermissionSets: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, OBJ_SEARCH_TYPE, PERMISSION_SET_GROUP_QUERY_CONDITION) : 
                queryPermissionsApex(OBJ_SEARCH_TYPE, PERMISSION_SET_GROUP_QUERY_CONDITION, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static QueryResult getApexSecurityForAllProfiles(String servicePath, Integer position){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getApexSecurityForAllProfiles: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, APEX_SEARCH_TYPE, PROFILE_QUERY_CONDITION + APEX_CONDITIONS) : 
                queryPermissionsApex(APEX_SEARCH_TYPE, PROFILE_QUERY_CONDITION + APEX_CONDITIONS, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all profiles', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getApexSecurityForAllPermissionSets(String servicePath, Integer position) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getApexSecurityForAllPermissionSets: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, APEX_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION + APEX_CONDITIONS) : 
                queryPermissionsApex(APEX_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION + APEX_CONDITIONS, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static QueryResult getApexSecurityForAllPermissionSetGroups(String servicePath, Integer position) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getApexSecurityForAllPermissionSetGroups: servicePath={0}, position={1}', new Object[] { servicePath, position });
            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, APEX_SEARCH_TYPE, PERMISSION_SET_GROUP_QUERY_CONDITION + APEX_CONDITIONS) : 
                queryPermissionsApex(APEX_SEARCH_TYPE, PERMISSION_SET_GROUP_QUERY_CONDITION + APEX_CONDITIONS, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static QueryResult getObjectLevelSecurityForUser(String servicePath, Integer position, String userId){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getObjectLevelSecurityForUser: servicePath={0}, userId={1}', new Object[] { servicePath, userId});
            UserPermissionsDetails userPermissionDetails = getUserPermissionsDetails(userId);

            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, OBJ_SEARCH_TYPE, getCompleteUserQueryCondition(userPermissionDetails)) : 
                queryPermissionsApex(OBJ_SEARCH_TYPE, getCompleteUserQueryCondition(userPermissionDetails), position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for user', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static QueryResult getFieldLevelSecurityForUser(String servicePath, Integer position, String userId){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getFieldLevelSecurityForUser: servicePath={0}, userId={1}', new Object[] { servicePath, userId});
            UserPermissionsDetails userPermissionDetails = getUserPermissionsDetails(userId);

            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, FLS_SEARCH_TYPE, getCompleteUserQueryCondition(userPermissionDetails)) : 
                queryPermissionsApex(FLS_SEARCH_TYPE, getCompleteUserQueryCondition(userPermissionDetails), position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for user', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static QueryResult getApexSecurityForUser(String servicePath, Integer position, String userId){
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getApexSecurityForUser: servicePath={0}, userId={1}', new Object[] { servicePath, userId});
            UserPermissionsDetails userPermissionDetails = getUserPermissionsDetails(userId);

            return shouldUseRestQueryModel() ? 
                queryPermissionsRest(servicePath, position, APEX_SEARCH_TYPE, getCompleteUserQueryCondition(userPermissionDetails) + APEX_CONDITIONS) : 
                queryPermissionsApex(APEX_SEARCH_TYPE, getCompleteUserQueryCondition(userPermissionDetails) + APEX_CONDITIONS, position);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for user', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Returns whether the field permission views should start with fields without FLS shown, taken
     *              from the optional `Permissions_Explorer_Show_Fields_Without_FLS` Global Setting. Without the
     *              setting they stay hidden.
     *
     *              Deliberately not `cacheable=true`: the Lightning action cache would keep serving the
     *              previous value after an admin changes the setting, so the new default would not apply on
     *              the next page load. This runs once per component initialization.
     * @return      True when the views should show fields without FLS without the user asking.
     */
    @AuraEnabled
    public static Boolean getShowFieldsWithoutFlsByDefault() {
        try {
            Boolean result = rflib_GlobalSettings.showFieldsWithoutFlsInPermissionsExplorerOrDefault;
            rflib_LoggerUtil.logInternal(LOGGER, 'getShowFieldsWithoutFlsByDefault: {0}', new Object[] { result });
            return result;
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve the fields without FLS setting', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Returns the fields of the given objects that cannot be controlled by Field Level Security,
     *              i.e. required custom fields, master-detail fields and standard system fields. Salesforce never
     *              stores a `FieldPermissions` record for those fields, so they are invisible to the FLS queries
     *              above. Their access is determined by the object permission instead.
     * @param  objectApiNames The objects to inspect, limited to `MAX_DESCRIBE_BATCH_SIZE` per invocation.
     * @return                One entry per resolvable object, each listing its non-permissionable fields
     *                        and whether each of them can be written.
     */
    @AuraEnabled(cacheable = true)
    public static List<ObjectFieldInfo> getNonPermissionableFields(List<String> objectApiNames) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'getNonPermissionableFields: numObjects={0}', new Object[] { objectApiNames?.size() });

            if (objectApiNames == null || objectApiNames.isEmpty()) {
                return new List<ObjectFieldInfo>();
            }

            if (objectApiNames.size() > MAX_DESCRIBE_BATCH_SIZE) {
                throw new rflib_InvalidArgumentException(
                    'objectApiNames',
                    'Number of objects (' + objectApiNames.size() + ') exceeds the limit of ' + MAX_DESCRIBE_BATCH_SIZE
                );
            }

            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            List<String> resolvableNames = new List<String>();
            for (String objectApiName : objectApiNames) {
                if (globalDescribe.containsKey(objectApiName)) {
                    resolvableNames.add(objectApiName);
                } else {
                    // A single object the running user cannot see must not fail the whole batch.
                    rflib_LoggerUtil.logInternal(LOGGER, 'Skipping object that cannot be described: {0}', new Object[] { objectApiName });
                }
            }

            List<ObjectFieldInfo> result = new List<ObjectFieldInfo>();
            if (resolvableNames.isEmpty()) {
                return result;
            }

            Integer heapThreshold = (Limits.getLimitHeapSize() * describeHeapSafetyRatio).intValue();

            // DEFERRED keeps child relationships and record types out of the describe; only the
            // field map below is actually needed and it is by far the cheaper half.
            for (
                Schema.DescribeSObjectResult objectDescribe : Schema.describeSObjects(
                    resolvableNames,
                    SObjectDescribeOptions.DEFERRED
                )
            ) {
                ObjectFieldInfo info = new ObjectFieldInfo(objectDescribe.getName());

                for (Schema.SObjectField field : objectDescribe.fields.getMap().values()) {
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

                    if (!fieldDescribe.isPermissionable() && fieldDescribe.getName() != 'Id') {
                        info.fields.add(new FieldAccessInfo(fieldDescribe.getName(), fieldDescribe.isUpdateable()));
                    }
                }

                info.fields.sort();
                result.add(info);

                if (Limits.getHeapSize() > heapThreshold) {
                    throw new rflib_InvalidArgumentException(
                        'objectApiNames',
                        'Describing these objects would exceed the available heap. ' +
                        result.size() + ' of ' + resolvableNames.size() +
                        ' objects were processed before reaching ' + Limits.getHeapSize() +
                        ' of ' + Limits.getLimitHeapSize() + ' bytes. Retry with fewer objects.'
                    );
                }
            }

            rflib_LoggerUtil.logInternal(LOGGER, 'getNonPermissionableFields: resolved {0} objects', new Object[] { result.size() });
            return result;
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve non-permissionable fields', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    private static String getCompleteUserQueryCondition(UserPermissionsDetails userPermissionDetails) {
        List<String> permissionSetAndGroupIds = new List<String> ( userPermissionDetails.permissionSets );
        permissionSetAndGroupIds.addAll(userPermissionDetails.permissionSetGroups);

        String permissionSetsAsQueryString = rflib_StringUtil.convertListToStringForQuery(permissionSetAndGroupIds);

        return String.format(USER_QUERY_CONDITION, new String[] { '\'' + userPermissionDetails.profileId + '\'', permissionSetsAsQueryString });
    }

    private static UserPermissionsDetails getUserPermissionsDetails(String userId) {
        // Query for the User and related Profile information
        User userRecord = [SELECT Id, ProfileId FROM User WHERE Id = :userId];

        // Query for the Permission Sets and Permission Set Groups assigned to the User
        List<PermissionSetAssignment> permSetAssignments = [SELECT PermissionSet.Name, PermissionSet.IsOwnedByProfile, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :userId];

        // Prepare the response
        UserPermissionsDetails details = new UserPermissionsDetails();
        details.userId = userRecord.Id;
        details.profileId = userRecord.ProfileId;

        for (PermissionSetAssignment psa : permSetAssignments) {
            if (psa.PermissionSet?.IsOwnedByProfile) {
                // Skip as it's part of the profile
                continue;
            }
            
            if (psa.PermissionSetId != null) {
                details.permissionSets.add(psa.PermissionSetId);
            } else {
                details.permissionSetGroups.add(psa.PermissionSetGroupId);
            }
        }

        return details;
    }
        
    private static Boolean shouldUseRestQueryModel() {
        Boolean result = rflib_GlobalSettings.useRestQueryModeForPermissionRetrievalOrDefault;
        rflib_LoggerUtil.logInternal(LOGGER, 'REST API Enabled: {0}', new Object[] { result } );
        return result;
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static QueryResult queryPermissionsApex(String searchType, String condition, Integer position) {       
        
        switch on (searchType) {
            when 'OBJ' {
                String fieldSelection = OBJ_FIELDS;
                String tableName = OBJ_TABLE;
                String sortOrder = OBJ_ORDER;
                String query = fieldSelection + tableName + condition + sortOrder;
                String queryLimit = ' LIMIT ' + APEX_QUERY_RECORD_LIMIT;

                LOGGER.debug('Final query: ' + query);

                if (position != null) {
                    rflib_DatabaseCursorQueryResult result = queryExecutor.fetch(query, position, APEX_CURSOR_RESULT_SIZE);
                    return convertToPermissionInfo((List<ObjectPermissions>) result.records, result.position, result.totalQueryNumRecords);
                } else {
                    Integer totalNumOfRecords = queryExecutor.countQuery(COUNT + tableName + condition);
                    List<ObjectPermissions> result = (List<ObjectPermissions>) queryExecutor.query(query + queryLimit);
                    return convertToPermissionInfo(result, null, totalNumOfRecords);
                }
            }

            when 'FLS' {
                String fieldSelection = FLS_FIELDS;
                String tableName = FLS_TABLE;
                String sortOrder = FLS_ORDER;
                String query = fieldSelection + tableName + condition + sortOrder;
                String queryLimit = ' LIMIT ' + APEX_QUERY_RECORD_LIMIT;

                LOGGER.debug('Final query: {0}, {1}' + new Object[] {query, position});

                if (position != null) {
                    rflib_DatabaseCursorQueryResult result = queryExecutor.fetch(query, position, APEX_CURSOR_RESULT_SIZE);
                    return convertToPermissionInfo((List<FieldPermissions>) result.records, result.position, result.totalQueryNumRecords);
                } else {
                    Integer totalNumOfRecords = queryExecutor.countQuery(COUNT + tableName + condition);
                    List<FieldPermissions> result = (List<FieldPermissions>) queryExecutor.query(query + queryLimit);
                    return convertToPermissionInfo(result, null, totalNumOfRecords);
                }
            }

            when else {
                String fieldSelection = APEX_FIELDS;
                String tableName = APEX_TABLE;
                String sortOrder = APEX_ORDER;
                String query = fieldSelection + tableName + condition + sortOrder;
                String queryLimit = ' LIMIT ' + APEX_QUERY_RECORD_LIMIT;

                LOGGER.debug('Final query: ' + query);

                if (position != null) {
                    rflib_DatabaseCursorQueryResult result = queryExecutor.fetch(query, position, APEX_CURSOR_RESULT_SIZE);
                    return convertToPermissionInfo((List<SetupEntityAccess>) result.records, result.position, result.totalQueryNumRecords);
                } else {
                    Integer totalNumOfRecords = queryExecutor.countQuery(COUNT + tableName + condition);
                    List<SetupEntityAccess> result = (List<SetupEntityAccess>) queryExecutor.query(query + queryLimit);
                    return convertToPermissionInfo(result, null, totalNumOfRecords);
                }
            }
        } 
    }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static QueryResult queryPermissionsRest(String servicePath, Integer position, String searchType, String condition) {
        String fieldSelection;
        String tableName;
        String sortOrder;

        switch on (searchType) {
            when 'OBJ' {
                fieldSelection = OBJ_FIELDS;
                tableName = OBJ_TABLE;
                sortOrder = OBJ_ORDER;
            }

            when 'FLS' {
                fieldSelection = FLS_FIELDS;
                tableName = FLS_TABLE;
                sortOrder = FLS_ORDER;
            }

            when else {
                fieldSelection = APEX_FIELDS;
                tableName = APEX_TABLE;
                sortOrder = APEX_ORDER;
            }
        }

        Integer totalNumOfRecords = queryExecutor.countQuery(COUNT + tableName + condition);
        
        if (totalNumOfRecords <= APEX_QUERY_RECORD_LIMIT) {
            rflib_LoggerUtil.logInternal(LOGGER, 'Expect {0} of records returned, using Apex query instead of REST', new Object[] { totalNumOfRecords });
            return queryPermissionsApex(searchType, condition, position);
        }
        
        String query = fieldSelection + tableName + condition + sortOrder;
        String urlPath = String.isNotBlank(servicePath) ? servicePath : '/services/data/v61.0/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        
        rflib_HttpRequest req = new rflib_HttpRequest(); 
        req.suppressMocking = true;       
        req.setEndpoint('callout:rflib_SF_REST_API' + urlPath);
        req.setMethod('GET');
        
        HTTPResponse res = req.send();

        if (res.getStatusCode() != 200) {
            List<RestError> errors = (List<RestError>) JSON.deserialize(res.getBody(), List<RestError>.class);
            throw createRestException(errors);
        }
            
        QueryResult result = (QueryResult) JSON.deserialize(res.getBody(), QueryResult.class);
        rflib_LoggerUtil.logInternal(LOGGER, 'REST results received: size=' + result.records.size());
        result.totalNumOfRecords = totalNumOfRecords;

        if (searchType == FLS_SEARCH_TYPE) {
            for (PermissionInfo pi : result.records) {
                pi.Field = pi.Field.substringAfter('.');
            }
        } else if (searchType == APEX_SEARCH_TYPE) {
            Map<Id, ApexInfo> entityInfo = getEntityInfo(result);
            for (PermissionInfo pi : result.records) {
                pi.updateSObjectType(entityInfo);
            }
        }
        return result;
    }

    private static QueryResult convertToPermissionInfo(List<FieldPermissions> fieldPermissionsList, Integer position, Integer totalNumOfRecords) {
        QueryResult result = new QueryResult();
        result.totalNumOfRecords = totalNumOfRecords;
        result.nextPosition = position == null ? fieldPermissionsList.size() : position + fieldPermissionsList.size();

        for (FieldPermissions fp : fieldPermissionsList) {
            result.records.add(new PermissionInfo(fp));
        }
        rflib_LoggerUtil.logInternal(LOGGER, 'Result recordsSize={0}, totalNumOfRecords={1}, nextRecordsUrl={2}, nextPosition={3}', new Object[] {result.records.size(), result.totalNumOfRecords, result.nextRecordsUrl, result.nextPosition} );
        return result;
    }

    private static QueryResult convertToPermissionInfo(List<ObjectPermissions> objectPermissionsList, Integer position, Integer totalNumOfRecords) {
        QueryResult result = new QueryResult();
        result.totalNumOfRecords = totalNumOfRecords;
        result.nextPosition = position == null ? objectPermissionsList.size() : position + objectPermissionsList.size();

        for (ObjectPermissions op : objectPermissionsList) {
            result.records.add(new PermissionInfo(op));
        }
        rflib_LoggerUtil.logInternal(LOGGER, 'Result recordsSize={0}, totalNumOfRecords={1}, nextRecordsUrl={2}, nextPosition={3}', new Object[] {result.records.size(), result.totalNumOfRecords, result.nextRecordsUrl, result.nextPosition} );
        return result;
    }
    
    private static QueryResult convertToPermissionInfo(List<SetupEntityAccess> apexPermissionsList, Integer position, Integer totalNumOfRecords) {
        QueryResult result = new QueryResult();
        result.totalNumOfRecords = totalNumOfRecords;
        result.nextPosition = position == null ? apexPermissionsList.size() : position + apexPermissionsList.size();

        Map<Id, ApexInfo> entityInfo = getEntityInfo(apexPermissionsList);

        for (SetupEntityAccess ap : apexPermissionsList) {
            result.records.add(new PermissionInfo(ap, entityInfo));
        }
        rflib_LoggerUtil.logInternal(LOGGER, 'Result recordsSize={0}, totalNumOfRecords={1}, nextRecordsUrl={2}, nextPosition={3}', new Object[] {result.records.size(), result.totalNumOfRecords, result.nextRecordsUrl, result.nextPosition} );
        return result;
    }

    private static Map<Id, ApexInfo> getEntityInfo(List<SetupEntityAccess> apexPermissionsList) {
        Set<Id> apexClassIds = new Set<Id>();
        Set<Id> apexPageIds = new Set<Id>();

        for (SetupEntityAccess ea : apexPermissionsList) {
            if (ea.SetupEntityType == 'ApexClass') {
                apexClassIds.add(ea.SetupEntityId);
            } else {
                apexPageIds.add(ea.SetupEntityId);
            }
        }

        return getEntityInfo(apexClassIds, apexPageIds);
    }

    private static Map<Id, ApexInfo> getEntityInfo(QueryResult restResult) {
        Set<Id> apexClassIds = new Set<Id>();
        Set<Id> apexPageIds = new Set<Id>();
        
        for (PermissionInfo pi : restResult.records) {
            if (pi.SetupEntityType == 'ApexClass') {
                apexClassIds.add(pi.SetupEntityId);
            } else {
                apexPageIds.add(pi.SetupEntityId);
            }
        }

        return getEntityInfo(apexClassIds, apexPageIds);
    }
        
    private static Map<Id, ApexInfo> getEntityInfo(Set<Id> apexClassIds, Set<Id> apexPageIds) {
        Map<Id, ApexInfo> result = new Map<Id, ApexInfo>();
        for (ApexClass ac : [SELECT Id, NamespacePrefix, Name FROM ApexClass WHERE Id IN :apexClassIds]) {
            result.put(ac.Id, new ApexInfo(ac.NamespacePrefix, ac.Name));
        }

        for (ApexPage ap : [SELECT Id, NamespacePrefix, Name FROM ApexPage WHERE Id IN :apexPageIds]) {
            result.put(ap.Id, new ApexInfo(ap.NamespacePrefix, ap.Name));
        }

        rflib_LoggerUtil.logInternal(LOGGER, 'EntityInfo=' + result);

        return result;
    }

    private static RestException createRestException(List<RestError> errors) {
        if (errors.size() == 0) {
            return new RestException('Unknown REST error');
        }

        return new RestException(errors.get(0).message);
    }

    public class QueryResult {
        @AuraEnabled public List<PermissionInfo> records = new List<PermissionInfo>();
        @AuraEnabled public String nextRecordsUrl;
        @AuraEnabled public Integer nextPosition;
        @AuraEnabled public Integer totalNumOfRecords;
    }

    @SuppressWarnings('PMD.VariableNamingConventions')
    public class ParentInfo {
        @AuraEnabled public Boolean IsOwnedByProfile;
        @AuraEnabled public String PermissionSetGroupId;
        @AuraEnabled public String Label;
        @AuraEnabled public ProfileInfo Profile = new ProfileInfo();

        public ParentInfo(Boolean isOwnedByProfile, String permissionSetGroupId, String label, String profileName) {
            this.IsOwnedByProfile = isOwnedByProfile;
            this.permissionSetGroupId = permissionSetGroupId;
            this.Label = label;
            this.Profile.Name = profileName;
        }
    }

    @SuppressWarnings('PMD.VariableNamingConventions')
    public class ProfileInfo {
        @AuraEnabled public String Name;
    }
    
    @SuppressWarnings('PMD.VariableNamingConventions')
    public class PermissionInfo {
        @AuraEnabled public ParentInfo Parent;
        @AuraEnabled public String SobjectType;
        @AuraEnabled public String SetupEntityId;
        @AuraEnabled public String SetupEntityType;
        @AuraEnabled public String Field;
        @AuraEnabled public Boolean PermissionsEdit;
        @AuraEnabled public Boolean PermissionsRead;
        @AuraEnabled public Boolean PermissionsCreate;
        @AuraEnabled public Boolean PermissionsDelete;
        @AuraEnabled public Boolean PermissionsViewAllFields;
        @AuraEnabled public Boolean PermissionsViewAllRecords;
        @AuraEnabled public Boolean PermissionsModifyAllRecords;

        @AuraEnabled public String SecurityType {
            get {
                return this.Parent.IsOwnedByProfile ? 'Profile' : String.isBlank(this.Parent.PermissionSetGroupId) ? 'PermissionSet' : 'PermissionSetGroup';
            }
        }

        @AuraEnabled public String SecurityObjectName {
            get {
                return this.Parent.IsOwnedByProfile ? this.Parent.Profile.Name : this.Parent.Label;
            }
        }

        @AuraEnabled public String Label {
            get {
                return this.SecurityType + ': ' + this.SecurityObjectName;
            }
        }

        @AuraEnabled public String ApexLabel {
            get {
                return this.SetupEntityType + ': ' + this.SobjectType;
            }
        }

        public PermissionInfo(FieldPermissions record) {
            this.SobjectType = record.SobjectType;
            this.Field = record.Field.substringAfter('.');
            this.PermissionsEdit = record.PermissionsEdit;
            this.PermissionsRead = record.PermissionsRead;

            this.Parent = new ParentInfo(record.Parent.IsOwnedByProfile, record.Parent.PermissionSetGroupId, record.Parent.Label, record.Parent.Profile.Name);
        }
        
        public PermissionInfo(ObjectPermissions record) {
            this.SobjectType = record.SobjectType;
            this.PermissionsEdit = record.PermissionsEdit;
            this.PermissionsRead = record.PermissionsRead;
            this.PermissionsCreate = record.PermissionsCreate;
            this.PermissionsDelete = record.PermissionsDelete;
            this.PermissionsViewAllFields = record.PermissionsViewAllFields;
            this.PermissionsViewAllRecords = record.PermissionsViewAllRecords;
            this.PermissionsModifyAllRecords = record.PermissionsModifyAllRecords;

            this.Parent = new ParentInfo(record.Parent.IsOwnedByProfile, record.Parent.PermissionSetGroupId, record.Parent.Label, record.Parent.Profile.Name);
        }

        public PermissionInfo(SetupEntityAccess record, Map<Id, ApexInfo> entityInfo) {
            this.SetupEntityId = record.SetupEntityId;
            this.SetupEntityType = record.SetupEntityType;
            this.SobjectType = entityInfo.get(record.SetupEntityId).name;

            this.Parent = new ParentInfo(record.Parent.IsOwnedByProfile, record.Parent.PermissionSetGroupId, record.Parent.Label, record.Parent.Profile.Name);
        }

        public void updateSObjectType(Map<Id, ApexInfo> entityInfo) {
            this.SobjectType = entityInfo.get(this.SetupEntityId)?.name;
        } 
    }

    public class ObjectFieldInfo {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public List<FieldAccessInfo> fields = new List<FieldAccessInfo>();

        public ObjectFieldInfo(String objectApiName) {
            this.objectApiName = objectApiName;
        }
    }

    /**
     * @description A field that Field Level Security cannot control. Such a field is always readable
     *              when the parent can read the object, so only whether it can be written varies.
     */
    public class FieldAccessInfo implements Comparable {
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean isUpdateable;

        public FieldAccessInfo(String apiName, Boolean isUpdateable) {
            this.apiName = apiName;
            this.isUpdateable = isUpdateable;
        }

        public Integer compareTo(Object other) {
            return this.apiName.compareTo(((FieldAccessInfo) other).apiName);
        }
    }

    public class UserPermissionsDetails {
        public String userId;
        public String profileId;
        public Set<String> permissionSets = new Set<String>();
        public Set<String> permissionSetGroups = new Set<String>();
    }
    
    public class ApexInfo {
        public String name;

        public ApexInfo(String namespace, String name) {
            this.name = String.isNotBlank(namespace) 
                ? namespace + '__' + name
                : name;
        }
    }
    
    public class RestError {
        @AuraEnabled public String message;
        @AuraEnabled public String errorCode;
    }

    public class RestException extends Exception { }

}
