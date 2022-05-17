/*
 * Copyright (c) 2022 Johannes Fischer <fischer.jh@gmail.com>
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
@IsTest
private class rflib_UserPermAssignmentControllerTest {
    
    private static final PermissionSet CLIENT_LOGGING_PERM_SET = [SELECT Id, Name FROM PermissionSet WHERE Name = 'rflib_Enable_Client_Logging'];
    private static final PermissionSet OPS_CENTER_ACCESS_PERM_SET = [SELECT Id, Name FROM PermissionSet WHERE Name = 'rflib_Ops_Center_Access'];

    private static final User END_USER = rflib_UserFactory.insertAndRetrieve('John', 'Doe', 'Standard User');
    private static final User OPS_USER = rflib_UserFactory.insertAndRetrieve('Jane', 'Smith', 'System Administrator');

    private static void setup() {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        assignments.add(createAssignment(END_USER, CLIENT_LOGGING_PERM_SET));
        assignments.add(createAssignment(OPS_USER, CLIENT_LOGGING_PERM_SET));
        assignments.add(createAssignment(OPS_USER, OPS_CENTER_ACCESS_PERM_SET));

        insert assignments;
    }

    private static PermissionSetAssignment createAssignment(User u, PermissionSet permSet) {
        return new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = permSet.Id
        );
    }

    @IsTest
    private static void testGetUserPermissionAssignments_ShouldBeAssigned() {
        setup(); 

        Test.startTest();
        List<rflib_UserPermAssignmentController.UserPermissionAssignmentInfo> result = rflib_UserPermAssignmentController.getUserPermissionAssignments(CLIENT_LOGGING_PERM_SET.Name, true);
        Test.stopTest();

        System.assert(listContains(result, END_USER), 'Result did not contain end user');
        System.assert(listContains(result, OPS_USER), 'result did not contain ops user');
    }

    @IsTest
    private static void testGetUserPermissionAssignments_ShouldNotBeAssigned() {
        setup(); 
        
        Test.startTest();
        List<rflib_UserPermAssignmentController.UserPermissionAssignmentInfo> result = rflib_UserPermAssignmentController.getUserPermissionAssignments(OPS_CENTER_ACCESS_PERM_SET.Name, false);
        Test.stopTest();

        System.assert(listContains(result, END_USER), 'Result did not contain end user');
        System.assert( ! listContains(result, OPS_USER), 'Result should not contain ops user');
    }

    private static Boolean listContains(List<rflib_UserPermAssignmentController.UserPermissionAssignmentInfo> listToCheck, User u) {
        for (rflib_UserPermAssignmentController.UserPermissionAssignmentInfo info : listToCheck) {
            if (info.id == u.id) {
                return true;
            }
        }
        return false;
    }
}
