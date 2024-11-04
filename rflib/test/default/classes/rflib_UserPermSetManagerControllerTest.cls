/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_UserPermSetManagerControllerTest {
    
    private static final String PERM_SET_NAME = 'rflib_Ops_Center_Access';
    private static final String TEST_ALIAS_ADMIN = 'Alice';
    private static final String TEST_ALIAS_STANDARD = 'Bob';
    private static final String TEST_ALIAS_NO_PERM = 'Charlie';
    
    private static final User ADMIN_USER = rflib_TestUserFactory.insertAndRetrieve('Alice', 'Admin', 'System Administrator');
    private static final User STANDARD_USER = rflib_TestUserFactory.insertAndRetrieve('Bob', 'Viewer', 'Standard User');
    private static final User NO_PERMISSION_USER = rflib_TestUserFactory.insertAndRetrieve('Charlie', 'NoAccess', 'Standard User');
    
    private static void setupTestData() {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :PERM_SET_NAME LIMIT 1];
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        
        permSetAssignments.add(new PermissionSetAssignment(
            AssigneeId = ADMIN_USER.Id,
            PermissionSetId = permSet.Id
        ));
        
        permSetAssignments.add(new PermissionSetAssignment(
            AssigneeId = STANDARD_USER.Id,
            PermissionSetId = permSet.Id
        ));
        
        insert permSetAssignments;
    }
    
    private static Boolean listContains(List<rflib_UserPermSetManagerController.PermissionSetDTO> listToCheck, String permissionSetName) {
        for (rflib_UserPermSetManagerController.PermissionSetDTO dto : listToCheck) {
            if (dto.Name == permissionSetName) {
                return true;
            }
        }
        return false;
    }
    
    @IsTest
    private static void testGetAssignedPermissionSets_Success_AdminUser() {
        setupTestData();
        
        Test.startTest();
        List<rflib_UserPermSetManagerController.PermissionSetDTO> assignedPermSets = rflib_UserPermSetManagerController.getAssignedPermissionSets(TEST_ALIAS_ADMIN);
        Test.stopTest();
        
        Assert.areNotEqual(null, assignedPermSets, 'Assigned Permission Sets should not be null.');
        Assert.isTrue(listContains(assignedPermSets, PERM_SET_NAME), 'Admin user should have one Permission Set assigned.');
    }
    
    @IsTest
    private static void testGetAssignedPermissionSets_Success_StandardUser() {
        setupTestData();
        
        Test.startTest();
        List<rflib_UserPermSetManagerController.PermissionSetDTO> assignedPermSets = rflib_UserPermSetManagerController.getAssignedPermissionSets(TEST_ALIAS_STANDARD);
        Test.stopTest();
        
        Assert.areNotEqual(null, assignedPermSets, 'Assigned Permission Sets should not be null.');
        Assert.isTrue(listContains(assignedPermSets, PERM_SET_NAME), 'Standard user should have one Permission Set assigned.');
    }
    
    @IsTest
    private static void testGetAssignedPermissionSets_NoPermissionSets() {
        setupTestData();
        
        Test.startTest();
        List<rflib_UserPermSetManagerController.PermissionSetDTO> assignedPermSets = rflib_UserPermSetManagerController.getAssignedPermissionSets(TEST_ALIAS_NO_PERM);
        Test.stopTest();
        
        Assert.areNotEqual(null, assignedPermSets, 'Assigned Permission Sets should not be null.');
        Assert.isFalse(listContains(assignedPermSets, PERM_SET_NAME), 'User without permissions should have no Permission Sets assigned.');
    }
    
    @IsTest
    private static void testGetAssignedPermissionSets_InvalidAlias() {
        setupTestData();
        
        Test.startTest();
        List<rflib_UserPermSetManagerController.PermissionSetDTO> assignedPermSets = rflib_UserPermSetManagerController.getAssignedPermissionSets('invalidAlias');
        Test.stopTest();

        Assert.isTrue(assignedPermSets.isEmpty(), 'Assigned Permission Sets should be empty.');
    }
    
    @IsTest
    private static void testGetAllPermissionSets_Success() {
        setupTestData();
        
        Test.startTest();
        List<PermissionSet> allPermSets = rflib_UserPermSetManagerController.getAllPermissionSets();
        Test.stopTest();
        
        Assert.areNotEqual(null, allPermSets, 'All Permission Sets should not be null.');
        Assert.isTrue(allPermSets.size() >= 1, 'There should be at least one Permission Set available.');
        Boolean containsOpsCenterAccess = false;
        for (PermissionSet ps : allPermSets) {
            if (ps.Name == PERM_SET_NAME) {
                containsOpsCenterAccess = true;
                break;
            }
        }
        Assert.isTrue(containsOpsCenterAccess, 'All Permission Sets should include rflib_Ops_Center_Access.');
    }
    
    @IsTest
    private static void testAssignPermissionSet_Success() {
        setupTestData();
        
        PermissionSet newPermSet = [SELECT Id FROM PermissionSet WHERE Name = :PERM_SET_NAME LIMIT 1];
        String targetAlias = TEST_ALIAS_NO_PERM;
        
        Test.startTest();
        rflib_UserPermSetManagerController.assignPermissionSet(newPermSet.Id, targetAlias);
        Test.stopTest();
        
        List<PermissionSetAssignment> psaList = [SELECT Id FROM PermissionSetAssignment WHERE Assignee.Alias = :targetAlias AND PermissionSetId = :newPermSet.Id];
        Assert.isTrue(psaList.size() == 1, 'Permission Set should be assigned successfully.');
    }
    
    @IsTest
    private static void testAssignPermissionSet_InvalidPermissionSetId() {
        setupTestData();
        
        String targetAlias = TEST_ALIAS_NO_PERM;
        Id invalidPermSetId = '0PS000000000001'; // Invalid Permission Set ID prefix
        
        Test.startTest();
        try {
            rflib_UserPermSetManagerController.assignPermissionSet(invalidPermSetId, targetAlias);
            Assert.fail('Expected AuraHandledException was not thrown for invalid Permission Set ID.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Permission set doesn\'t exist'), 'Exception message should indicate invalid ID, was:' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testAssignPermissionSet_InvalidAlias() {
        setupTestData();
        
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :PERM_SET_NAME LIMIT 1];
        String invalidAlias = 'invalid';
        
        Test.startTest();
        try {
            rflib_UserPermSetManagerController.assignPermissionSet(permSet.Id, invalidAlias);
            Assert.fail('Expected AuraHandledException was not thrown for invalid alias.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('List has no rows for assignment'), 'Exception message should indicate no user found, was:' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testDeletePermissionSetAssignment_Success() {
        setupTestData();
        
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :PERM_SET_NAME LIMIT 1];
        String targetAlias = TEST_ALIAS_ADMIN;
        PermissionSetAssignment psa = [SELECT Id FROM PermissionSetAssignment WHERE Assignee.Alias = :targetAlias AND PermissionSetId = :permSet.Id LIMIT 1];
        
        Test.startTest();
        rflib_UserPermSetManagerController.deletePermissionSetAssignment(psa.Id);
        Test.stopTest();
        
        PermissionSetAssignment deletedPSA;
        try {
            deletedPSA = [SELECT Id FROM PermissionSetAssignment WHERE Id = :psa.Id LIMIT 1];
        } catch (QueryException qe) {
            deletedPSA = null;
        }
        Assert.areEqual(null, deletedPSA, 'Permission Set Assignment should be deleted successfully.');
    }
    
    @IsTest
    private static void testDeletePermissionSetAssignment_InvalidId() {
        setupTestData();
        
        Id invalidPSAId = '0PS000000000001'; // Invalid PermissionSetAssignment ID prefix
        
        Test.startTest();
        try {
            rflib_UserPermSetManagerController.deletePermissionSetAssignment(invalidPSAId);
            Assert.fail('Expected AuraHandledException was not thrown for invalid PermissionSetAssignment ID.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Invalid id value for this SObject type'), 'Exception message should indicate no record found, was:' + e.getMessage());
        }
        Test.stopTest();
    }
}
