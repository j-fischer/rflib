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
    
    @TestVisible private static final String COUNT = 'SELECT COUNT()';
    @TestVisible private static final String FLS_FIELDS = 'SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead';
    @TestVisible private static final String OBJ_FIELDS = 'SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords';
 
    @TestVisible private static final String FLS_TABLE = ' FROM FieldPermissions';
    @TestVisible private static final String OBJ_TABLE = ' FROM ObjectPermissions';

    @TestVisible private static final String PROFILE_QUERY_CONDITION = ' WHERE Parent.IsOwnedByProfile = true';
    @TestVisible private static final String PERMISSION_SET_QUERY_CONDITION = ' WHERE Parent.IsOwnedByProfile = false';
 
    @TestVisible private static final String FLS_ORDER = ' ORDER BY Parent.Profile.Name, Parent.Label, SobjectType, Field'; 
    @TestVisible private static final String OBJ_ORDER = ' ORDER BY Parent.Profile.Name, Parent.Label, SobjectType'; 

    @TestVisible private static rflib_Global_Setting__mdt queryMode = rflib_Global_Setting__mdt.getInstance('Permissions_Explorer_REST_API_Enabled');

    @TestVisible private static rflib_QueryExecutor queryExecutor  = new rflib_DatabaseQueryExecutor();

    @AuraEnabled(cacheable = true)
    public static QueryResult getFieldLevelSecurityForAllProfiles(String servicePath){
        try {
            LOGGER.info('getFieldLevelSecurityForAllProfiles: servicePath=' + servicePath);
            return useRestQueryModel() ? 
                queryFieldPermissionsRest(servicePath, FLS_SEARCH_TYPE, PROFILE_QUERY_CONDITION) : 
                queryFieldPermissionsApex(FLS_SEARCH_TYPE, PROFILE_QUERY_CONDITION);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all profiles', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getFieldLevelSecurityForAllPermissionSets(String servicePath) {
        try {
            LOGGER.info('getFieldLevelSecurityForAllPermissionSets: servicePath=' + servicePath);
            return useRestQueryModel() ? 
                queryFieldPermissionsRest(servicePath, FLS_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION) : 
                queryFieldPermissionsApex(FLS_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getObjectLevelSecurityForAllProfiles(String servicePath){
        try {
            LOGGER.info('getObjectLevelSecurityForAllProfiles: servicePath=' + servicePath);
            return useRestQueryModel() ? 
                queryFieldPermissionsRest(servicePath, OBJ_SEARCH_TYPE, PROFILE_QUERY_CONDITION) : 
                queryFieldPermissionsApex(OBJ_SEARCH_TYPE, PROFILE_QUERY_CONDITION);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all profiles', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static QueryResult getObjectLevelSecurityForAllPermissionSets(String servicePath){
        try {
            LOGGER.info('getObjectLevelSecurityForAllPermissionSets: servicePath=' + servicePath);
            return useRestQueryModel() ? 
                queryFieldPermissionsRest(servicePath, OBJ_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION) : 
                queryFieldPermissionsApex(OBJ_SEARCH_TYPE, PERMISSION_SET_QUERY_CONDITION);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all permission sets', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
        
    private static Boolean useRestQueryModel() {
        LOGGER.info('REST API Enabled: {0}', new Object[] { queryMode } );
        return String.isNotBlank(queryMode.Value__c) && Boolean.valueOf(queryMode.Value__c);
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static QueryResult queryFieldPermissionsApex(String searchType, String condition) {
        Boolean isFlsSearch = searchType == FLS_SEARCH_TYPE;

        String fieldSelection = isFlsSearch ? FLS_FIELDS : OBJ_FIELDS;
        String tableName = isFlsSearch ? FLS_TABLE : OBJ_TABLE;
        String sortOrder = isFlsSearch ? FLS_ORDER : OBJ_ORDER;
        String query = fieldSelection + tableName + condition + sortOrder;


        return isFlsSearch
            ? convertToPermissionInfo((List<FieldPermissions>) queryExecutor.query(query + ' LIMIT 49999'))
            : convertToPermissionInfo((List<ObjectPermissions>) queryExecutor.query(query + ' LIMIT 49999'));       
    }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static QueryResult queryFieldPermissionsRest(String servicePath, String searchType, String condition) {
        String fieldSelection = searchType == FLS_SEARCH_TYPE ? FLS_FIELDS : OBJ_FIELDS;
        String tableName = searchType == FLS_SEARCH_TYPE ? FLS_TABLE : OBJ_TABLE;
        String sortOrder = searchType == FLS_SEARCH_TYPE ? FLS_ORDER : OBJ_ORDER;

        Integer totalNumOfRecords = queryExecutor.countQuery(COUNT + tableName + condition);
        
        if (totalNumOfRecords < 50000) {
            LOGGER.info('Expect {0} of records returned, using Apex query instead of REST', new Object[] { totalNumOfRecords });
            return queryFieldPermissionsApex(searchType, condition);
        }
        
        String query = fieldSelection + tableName + condition + sortOrder;
        String urlPath = String.isNotBlank(servicePath) ? servicePath : '/services/data/v51.0/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        
        rflib_HttpRequest req = new rflib_HttpRequest();        
        req.setEndpoint('callout:rflib_SF_REST_API' + urlPath);
        req.setMethod('GET');
        
        HTTPResponse res = req.send();

        if (res.getStatusCode() != 200) {
            List<RestError> errors = (List<RestError>) JSON.deserialize(res.getBody(), List<RestError>.class);
            throw createRestException(errors);
        }
            
        QueryResult result = (QueryResult) JSON.deserialize(res.getBody(), QueryResult.class);
        result.totalNumOfRecords = totalNumOfRecords;

        if (searchType == FLS_SEARCH_TYPE) {
            for (PermissionInfo pi : result.records) {
                pi.Field = pi.Field.substringAfter('.');
            }
        }
        return result;
    }

    private static QueryResult convertToPermissionInfo(List<FieldPermissions> fieldPermissionsList) {
        QueryResult result = new QueryResult();
        result.totalNumOfRecords = fieldPermissionsList.size();

        for (FieldPermissions fp : fieldPermissionsList) {
            result.records.add(new PermissionInfo(fp));
        }
        return result;
    }

    private static QueryResult convertToPermissionInfo(List<ObjectPermissions> objectPermissionsList) {
        QueryResult result = new QueryResult();
        result.totalNumOfRecords = objectPermissionsList.size();

        for (ObjectPermissions op : objectPermissionsList) {
            result.records.add(new PermissionInfo(op));
        }
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
        @AuraEnabled public Integer totalNumOfRecords;
    }

    @SuppressWarnings('PMD.VariableNamingConventions')
    public class ParentInfo {
        @AuraEnabled public Boolean IsOwnedByProfile;
        @AuraEnabled public String Label;
        @AuraEnabled public ProfileInfo Profile = new ProfileInfo();

        public ParentInfo(Boolean isOwnedByProfile, String label, String profileName) {
            this.IsOwnedByProfile = isOwnedByProfile;
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
        @AuraEnabled public String Field;
        @AuraEnabled public Boolean PermissionsEdit;
        @AuraEnabled public Boolean PermissionsRead;
        @AuraEnabled public Boolean PermissionsCreate;
        @AuraEnabled public Boolean PermissionsDelete;
        @AuraEnabled public Boolean PermissionsViewAllRecords;
        @AuraEnabled public Boolean PermissionsModifyAllRecords;

        @AuraEnabled public String SecurityType {
            get {
                return this.Parent.IsOwnedByProfile ? 'Profile' : 'PermissionSet';
            }
        }
        @AuraEnabled public String SecurityObjectName {
            get {
                return this.Parent.IsOwnedByProfile ? this.Parent.Profile.Name : this.Parent.Label;
            }
        }

        public PermissionInfo(FieldPermissions record) {
            this.SobjectType = record.SobjectType;
            this.Field = record.Field.substringAfter('.');
            this.PermissionsEdit = record.PermissionsEdit;
            this.PermissionsRead = record.PermissionsRead;

            this.Parent = new ParentInfo(record.Parent.IsOwnedByProfile, record.Parent.Label, record.Parent.Profile.Name);
        }
        
        public PermissionInfo(ObjectPermissions record) {
            this.SobjectType = record.SobjectType;
            this.PermissionsEdit = record.PermissionsEdit;
            this.PermissionsRead = record.PermissionsRead;
            this.PermissionsCreate = record.PermissionsCreate;
            this.PermissionsDelete = record.PermissionsDelete;
            this.PermissionsViewAllRecords = record.PermissionsViewAllRecords;
            this.PermissionsModifyAllRecords = record.PermissionsModifyAllRecords;

            this.Parent = new ParentInfo(record.Parent.IsOwnedByProfile, record.Parent.Label, record.Parent.Profile.Name);
        }
    }
    
    public class RestError {
        @AuraEnabled public String message;
        @AuraEnabled public String errorCode;
    }

    public class RestException extends Exception { }

}
