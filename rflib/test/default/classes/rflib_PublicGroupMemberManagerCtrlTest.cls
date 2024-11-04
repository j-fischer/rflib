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
private class rflib_PublicGroupMemberManagerCtrlTest {
    
    private static final String TEST_GROUP_API_NAME = 'rflib_Ops_Center_Members_Test';
    
    private static final User ADMIN_USER = rflib_TestUserFactory.insertAndRetrieve('Alice', 'Admin', 'System Administrator');
    private static final User STANDARD_USER = rflib_TestUserFactory.insertAndRetrieve('Bob', 'Viewer', 'Standard User');
    private static final User NON_MEMBER = rflib_TestUserFactory.insertAndRetrieve('Grace', 'Ghost', 'Standard User');
    
    private static Id testGroupId;
    
    private static void setupTestData() {
        Group testGroup = new Group(
            Name = TEST_GROUP_API_NAME,
            DeveloperName = TEST_GROUP_API_NAME,
            Type = 'Regular'
        );
        insert testGroup;
        testGroupId = testGroup.Id;
        
        List<GroupMember> initialMembers = new List<GroupMember>();
        initialMembers.add(new GroupMember(
            GroupId = testGroupId,
            UserOrGroupId = ADMIN_USER.Id
        ));
        initialMembers.add(new GroupMember(
            GroupId = testGroupId,
            UserOrGroupId = STANDARD_USER.Id
        ));
        insert initialMembers;
    }
    
    private static Boolean listContains(List<User> listToCheck, User u) {
        for (User user : listToCheck) {
            if (user.Id == u.Id) {
                return true;
            }
        }
        return false;
    }
    
    @IsTest
    private static void testCanUserModifyGroupMemberships_WithPermissions() {
        setupTestData();
        
        Boolean canModify;
        Test.startTest();
        System.runAs(ADMIN_USER) {
            canModify = rflib_PublicGroupMemberManagerController.canUserModifyGroupMemberships();
        }
        Test.stopTest();
        Assert.isTrue(canModify, 'User with edit permissions should be able to modify group memberships.');
    }
    
    @IsTest
    private static void testGetGroupMembers_Success() {
        setupTestData();
        
        Test.startTest();
        List<User> members = rflib_PublicGroupMemberManagerController.getGroupMembers(TEST_GROUP_API_NAME);
        Test.stopTest();
        
        Assert.areEqual(2, members.size(), 'There should be 2 group members.');
        Assert.isTrue(listContains(members, ADMIN_USER), 'Admin user should be a member of the group.');
        Assert.isTrue(listContains(members, STANDARD_USER), 'Standard user should be a member of the group.');
    }
    
    @IsTest
    private static void testGetGroupMembers_NonExistentGroup() {
        setupTestData();
        
        Test.startTest();
        try {
            rflib_PublicGroupMemberManagerController.getGroupMembers('NonExistentGroup');
            Assert.fail('Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error fetching group members: List has no rows for assignment'), 
                'Exception message should indicate non-existence, was: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testAddUserToGroup_Success() {
        setupTestData();
        
        User newUser;
        Test.startTest();
        System.runAs(ADMIN_USER) {
            newUser = rflib_TestUserFactory.insertAndRetrieve('Dave', 'NewMember', 'Standard User');
            rflib_PublicGroupMemberManagerController.addUserToGroup(TEST_GROUP_API_NAME, newUser.Id);
        }
        Test.stopTest();
        
        List<User> members = [SELECT Id FROM User WHERE Id IN (
            SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :testGroupId
        )];
        Assert.areEqual(3, members.size(), 'There should be 3 group members after addition.');
        Boolean isAdded = false;
        for (User u : members) {
            if (u.Id == newUser.Id) {
                isAdded = true;
                break;
            }
        }
        Assert.isTrue(isAdded, 'New user should be added to the group.');
    }
    
    @IsTest
    private static void testAddUserToGroup_UserAlreadyMember() {
        setupTestData();
        
        Test.startTest();
        System.runAs(ADMIN_USER) {
            try {
                rflib_PublicGroupMemberManagerController.addUserToGroup(TEST_GROUP_API_NAME, ADMIN_USER.Id);
                Assert.fail('Expected AuraHandledException was not thrown for already existing member.');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('already a member'), 
                    'Exception message should indicate user is already a member.');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testAddUserToGroup_NonExistentGroup() {
        setupTestData();
        
        User newUser;
        Test.startTest();
        System.runAs(ADMIN_USER) {
            newUser = rflib_TestUserFactory.insertAndRetrieve('Eve', 'Ghost', 'Standard User');
            try {
                rflib_PublicGroupMemberManagerController.addUserToGroup('NonExistentGroup', newUser.Id);
                Assert.fail('Expected AuraHandledException was not thrown for non-existent group.');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('Error adding user to group: List has no rows for assignment'), 
                    'Exception message should indicate non-existence of group, was: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testRemoveUserFromGroup_Success() {
        setupTestData();
        
        Test.startTest();
        System.runAs(ADMIN_USER) {
            rflib_PublicGroupMemberManagerController.removeUserFromGroup(TEST_GROUP_API_NAME, STANDARD_USER.Id);
        }
        Test.stopTest();

        List<User> members = [SELECT Id FROM User WHERE Id IN (
            SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :testGroupId
        )];
        Assert.areEqual(1, members.size(), 'There should be 1 group member after removal.');
        Assert.isTrue(members[0].Id == ADMIN_USER.Id, 'Only Admin user should remain in the group.');
    }
    
    @IsTest
    private static void testRemoveUserFromGroup_UserNotMember() {
        setupTestData();
        
        Test.startTest();
        System.runAs(ADMIN_USER) {            
            try {
                rflib_PublicGroupMemberManagerController.removeUserFromGroup(TEST_GROUP_API_NAME, NON_MEMBER.Id);
                Assert.fail('Expected AuraHandledException was not thrown for non-member user.');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('is not a member'), 
                    'Exception message should indicate user is not a member.');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testRemoveUserFromGroup_NonExistentGroup() {
        setupTestData();
        
        Test.startTest();
        System.runAs(ADMIN_USER) {
            try {
                rflib_PublicGroupMemberManagerController.removeUserFromGroup('NonExistentGroup', ADMIN_USER.Id);
                Assert.fail('Expected AuraHandledException was not thrown for non-existent group.');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('Error removing user from group: List has no rows for assignment'), 
                    'Exception message should indicate non-existence of group, was: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
}
