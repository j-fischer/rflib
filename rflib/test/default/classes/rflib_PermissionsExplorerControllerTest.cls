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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_PermissionsExplorerControllerTest {
    
    private static final String FLS_RESPONSE = '{"done":true,"totalSize":1,"records":[{"attributes":{"type":"FieldPermissions","url":"/services/data/v59.0/sobjects/FieldPermissions/01k3F0000GacGodQQE"},"Parent":{"attributes":{"type":"PermissionSet","url":"/services/data/v59.0/sobjects/PermissionSet/0PS3F000001TP1bWAG"},"Label":"00ex00000018ozh_128_09_04_12_1","Profile":{"attributes":{"type":"Profile","url":"/services/data/v59.0/sobjects/Profile/00e3F00000184CaQAI"},"Name":"System Administrator"},"IsOwnedByProfile":true},"SobjectType":"MaintenancePlan","Field":"MaintenancePlan.DoesGenerateUponCompletion","PermissionsEdit":true,"PermissionsRead":true}]}'; // cspell:disable-line
    private static final String OBJ_RESPONSE = '{"done":true,"totalSize":1,"records":[{"attributes":{"type":"ObjectPermissions","url":"/services/data/v59.0/sobjects/ObjectPermissions/1103F00001g9hIQQAY"},"Parent":{"attributes":{"type":"PermissionSet","url":"/services/data/v59.0/sobjects/PermissionSet/0PS3F000001TP1SWAW"},"Label":"00eB0000000Qlc9IAC","Profile":{"attributes":{"type":"Profile","url":"/services/data/v59.0/sobjects/Profile/00e3F00000184CiQAI"},"Name":"Company Communities User"},"IsOwnedByProfile":true},"SobjectType":"Account","PermissionsRead":true,"PermissionsCreate":true,"PermissionsEdit":true,"PermissionsDelete":true,"PermissionsViewAllRecords":false,"PermissionsModifyAllRecords":false}]}'; // cspell:disable-line
    private static final String ERR_RESPONSE = '[{"message":"Session expired or invalid","errorCode":"INVALID_SESSION_ID"}]';

    private static final String FLS_PROFILE_QUERY = rflib_PermissionsExplorerController.FLS_FIELDS
        + rflib_PermissionsExplorerController.FLS_TABLE
        + rflib_PermissionsExplorerController.PROFILE_QUERY_CONDITION
        + rflib_PermissionsExplorerController.FLS_ORDER;

    private static final String FLS_PERMISSION_SET_QUERY = rflib_PermissionsExplorerController.FLS_FIELDS
        + rflib_PermissionsExplorerController.FLS_TABLE
        + rflib_PermissionsExplorerController.PERMISSION_SET_QUERY_CONDITION
        + rflib_PermissionsExplorerController.FLS_ORDER;
    
    private static final String FLS_USER_QUERY = rflib_PermissionsExplorerController.FLS_FIELDS
        + rflib_PermissionsExplorerController.FLS_TABLE
        + rflib_PermissionsExplorerController.USER_QUERY_CONDITION
        + rflib_PermissionsExplorerController.FLS_ORDER;
    
    private static final String OBJ_PROFILE_QUERY = rflib_PermissionsExplorerController.OBJ_FIELDS
        + rflib_PermissionsExplorerController.OBJ_TABLE
        + rflib_PermissionsExplorerController.PROFILE_QUERY_CONDITION
        + rflib_PermissionsExplorerController.OBJ_ORDER;

    private static final String OBJ_PERMISSION_SET_QUERY = rflib_PermissionsExplorerController.OBJ_FIELDS
        + rflib_PermissionsExplorerController.OBJ_TABLE
        + rflib_PermissionsExplorerController.PERMISSION_SET_QUERY_CONDITION
        + rflib_PermissionsExplorerController.OBJ_ORDER;

    private static final String OBJ_USER_QUERY = rflib_PermissionsExplorerController.OBJ_FIELDS
        + rflib_PermissionsExplorerController.OBJ_TABLE
        + rflib_PermissionsExplorerController.USER_QUERY_CONDITION
        + rflib_PermissionsExplorerController.OBJ_ORDER;

    private static final String ENDPOINT = 'callout:rflib_SF_REST_API';
    private static final String ENDPOINT_PATH = '/services/data/v59.0/query?q=';
    private static final String METHOD = 'GET';

    private static void setup(Boolean isRestApiEnabled) {
        rflib_GlobalSettings.SETTINGS.put('Permissions_Explorer_REST_API_Enabled', String.valueOf(isRestApiEnabled));
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetFieldLevelSecurityForAllProfiles_RestApiDisabled() {
        setup(false);

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();
        
        assertFieldPermissionsResult(records, 'Profile');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetFieldLevelSecurityForAllProfiles_RestApiEnabled_ResultOfLessThanMaxRecordLimitUsesApex() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT, 
            Database.query(FLS_PROFILE_QUERY +  + ' LIMIT ' + rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT)
        );

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();
        
        assertFieldPermissionsResult(records, 'Profile');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetFieldLevelSecurityForAllProfiles_RestApiEnabled_ResultOfMoreThanMaxRecordLimitUsesRest() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(FLS_PROFILE_QUERY, 'UTF-8'));
        HttpResponse resp = createResponse(FLS_RESPONSE);

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp));

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertFieldPermissionsResult(records, 'Profile');

        System.assert(records.get(0).Field.containsNone('.'));
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetFieldLevelSecurityForAllProfiles_RestApiEnabled_ResultOfMoreThanMaxRecordLimitUsesRest_RequestFails() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(FLS_PROFILE_QUERY, 'UTF-8'));
        HttpResponse resp = createResponse(401, ERR_RESPONSE);

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles(null);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals('Session expired or invalid', actualEx.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetFieldLevelSecurityForAllProfiles_Fails() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(FLS_PROFILE_QUERY, 'UTF-8'));
        CalloutException expectedEx = new CalloutException('something went wrong');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), expectedEx));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles(null);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals(expectedEx.getMessage(), actualEx.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetFieldLevelSecurityForAllPermissionSets_RestApiDisabled() {
        setup(false);

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        System.assertEquals([SELECT Parent.Label, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead 
        FROM FieldPermissions 
        WHERE Parent.IsOwnedByProfile = false 
        ORDER BY Parent.Profile.Name, Parent.Label, SobjectType, Field
        LIMIT :rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT].size(), records.size());
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetFieldLevelSecurityForAllPermissionSets_Fails() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(FLS_PERMISSION_SET_QUERY, 'UTF-8'));
        CalloutException expectedEx = new CalloutException('something went wrong');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), expectedEx));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets(null);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals(expectedEx.getMessage(), actualEx.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetFieldLevelSecurityUser_RestApiDisabled() {
        setup(false);

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForUser(null, UserInfo.getUserId());
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertUserPermissions(records);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetFieldLevelSecurityForUser_Fails() {
        setup(true);
        
        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(
            String.format(FLS_USER_QUERY, new String[] { '\'' + UserInfo.getProfileId() + '\'', getPermissionSetsAsQueryString()}), 
            'UTF-8'
        ));

        CalloutException expectedEx = new CalloutException('something went wrong');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), expectedEx));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getFieldLevelSecurityForUser(null, UserInfo.getUserId());
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals(expectedEx.getMessage(), actualEx.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetObjectLevelSecurityForAllProfiles_RestApiDisabled() {
        setup(false);

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertObjectPermissionsResult(records, 'Profile');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetObjectLevelSecurityForAllProfiles_RestApiEnabled_ResultOfLessThanMaxRecordLimitUsesApex() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT, 
            Database.query(OBJ_PROFILE_QUERY + ' LIMIT ' + rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT)
        );

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertObjectPermissionsResult(records, 'Profile');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetObjectLevelSecurityForAllProfiles_RestApiEnabled_ResultOfMoreThanMaxRecordLimitUsesRest() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(OBJ_PROFILE_QUERY, 'UTF-8'));
        HttpResponse resp = createResponse(OBJ_RESPONSE);

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp));

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertObjectPermissionsResult(records, 'Profile');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testGetObjectLevelSecurityForAllProfiles_Fails() {
        setup(true);

        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(OBJ_PROFILE_QUERY, 'UTF-8'));
        CalloutException expectedEx = new CalloutException('something went wrong');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), expectedEx));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles(null);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals(expectedEx.getMessage(), actualEx.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetObjectLevelSecurityForAllPermissionSets_RestApiDisabled() {
        setup(false);
        
        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertObjectPermissionsResult(records, 'PermissionSet');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetObjectLevelSecurityForAllPermissionSets_Fails() {
        setup(true);
        
        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(OBJ_PERMISSION_SET_QUERY, 'UTF-8'));
        CalloutException expectedEx = new CalloutException('something went wrong');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), expectedEx));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets(null);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals(expectedEx.getMessage(), actualEx.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetObjectLevelSecurityUser_RestApiDisabled() {
        setup(false);

        Test.startTest();
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForUser(null, UserInfo.getUserId());
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        Test.stopTest();

        assertUserPermissions(records);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetObjectLevelSecurityForUser_Fails() {
        setup(true);
        
        rflib_PermissionsExplorerController.queryExecutor = new rflib_MockQueryExecutor(
            rflib_PermissionsExplorerController.APEX_QUERY_RECORD_LIMIT + 1, 
            null
        );

        rflib_HttpRequest req = createRequest(ENDPOINT_PATH + EncodingUtil.urlEncode(
            String.format(OBJ_USER_QUERY, new String[] { '\'' + UserInfo.getProfileId() + '\'', getPermissionSetsAsQueryString()}), 
            'UTF-8'
        ));

        CalloutException expectedEx = new CalloutException('something went wrong');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), expectedEx));

        Test.startTest();
        try {
            rflib_PermissionsExplorerController.getObjectLevelSecurityForUser(null, UserInfo.getUserId());
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException actualEx) {
            System.assertEquals(expectedEx.getMessage(), actualEx.getMessage());
        }
        Test.stopTest();
    }

    private static void assertUserPermissions(List<rflib_PermissionsExplorerController.PermissionInfo> records) {
        System.assert(records.size() > 0);
        
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        System.assert(containsPermissionsForProfile(records, profileName), 'The profile for the current user was not returned by the User search');
    }

    private static void assertObjectPermissionsResult(List<rflib_PermissionsExplorerController.PermissionInfo> records, String expectedSecurityType) {
        System.assert(records.size() > 0);

        rflib_PermissionsExplorerController.PermissionInfo info = records.get(0);
        System.assertEquals(expectedSecurityType, info.securityType);
        System.assertNotEquals(null, info.PermissionsRead);
        System.assertNotEquals(null, info.PermissionsEdit);
        System.assertNotEquals(null, info.PermissionsCreate);
        System.assertNotEquals(null, info.PermissionsDelete);
    }

    private static void assertFieldPermissionsResult(List<rflib_PermissionsExplorerController.PermissionInfo> records, String expectedSecurityType) {
        System.assert(records.size() > 0);

        rflib_PermissionsExplorerController.PermissionInfo info = records.get(0);
        System.assertEquals(expectedSecurityType, info.securityType);
        System.assertNotEquals(null, info.PermissionsRead);
        System.assertNotEquals(null, info.PermissionsEdit);
    }

    private static Boolean containsPermissionsForProfile(List<rflib_PermissionsExplorerController.PermissionInfo> myObjectList, String profileName) {
        for (rflib_PermissionsExplorerController.PermissionInfo item : myObjectList) {
            if (item.SecurityType == 'Profile' && item.SecurityObjectName == profileName) {
                return true;
            }
        }
        return false;
    }

    private static String getPermissionSetsAsQueryString() {
        List<PermissionSetAssignment> permSetAssignments = [SELECT PermissionSet.Name, PermissionSet.IsOwnedByProfile, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()];
        List<String> permSetIds = new List<String>();
        for (PermissionSetAssignment psa : permSetAssignments) {
            if (psa.PermissionSet?.IsOwnedByProfile) {
                // Skip as it's part of the profile
                continue;
            }
            
            permSetIds.add(psa.PermissionSetId != null ? psa.PermissionSetId : psa.PermissionSetGroupId);
        }

        return rflib_StringUtil.convertListToStringForQuery(permSetIds);
    }

    private static HttpResponse createResponse(String body) {
        return createResponse(200, body);
    }

    private static HttpResponse createResponse(Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);

        return response;
    }

    private static rflib_HttpRequest createRequest(String path) {
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setEndpoint(ENDPOINT + path);
        req.setMethod(METHOD);

        return req;
    }
}
