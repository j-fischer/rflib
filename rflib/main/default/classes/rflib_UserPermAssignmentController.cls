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
public with sharing class rflib_UserPermAssignmentController {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_UserPermAssignmentController');

    @AuraEnabled
    public static List<UserPermissionAssignmentInfo> getUserPermissionAssignments(String permSetApiName, Boolean shouldBeAssigned){
        try {
            LOGGER.debug('getUserPermissionAssignments invoked: permSetApiName={0}, shouldBeAssigned={1}', new Object[] { permSetApiName, shouldBeAssigned });
            Set<Id> assignedUserIds = getAssignedUserIds(permSetApiName);
            
            return getUserPermissionAssignmentInfo(assignedUserIds, shouldBeAssigned);
        } catch (Exception ex) {
            LOGGER.error('Failed to get user permission assignments.', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    private static List<UserPermissionAssignmentInfo> getUserPermissionAssignmentInfo(Set<Id> assignedUserIds, Boolean shouldBeAssigned) {
        List<User> userRecords = shouldBeAssigned
            ? [SELECT Name, Email, Phone, Profile.Name FROM User WHERE IsActive = TRUE AND Id IN :assignedUserIds ORDER BY Name]
            : [SELECT Name, Email, Phone, Profile.Name FROM User WHERE IsActive = TRUE AND Id NOT IN :assignedUserIds ORDER BY Name];

        LOGGER.debug('userRecords=' + userRecords);

        List<UserPermissionAssignmentInfo> result = new List<UserPermissionAssignmentInfo>();
        for (User u : userRecords) {
            result.add(new UserPermissionAssignmentInfo(
                u.Id,
                u.Name,
                u.Email,
                u.Phone, 
                u.Profile.Name
            ));
        }
        return result;
    }
    
    private static Set<Id> getAssignedUserIds(String permSetApiName) {
        List<PermissionSetAssignment> permSetAssignments = [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = :permSetApiName];
        LOGGER.debug('permSetAssignments=' + permSetAssignments);
        
        Set<Id> result = new Set<Id>();
        for (PermissionSetAssignment psa : permSetAssignments) {
            result.add(psa.AssigneeId);
        }
        return result;
    }

    public class UserPermissionAssignmentInfo {
        @AuraEnabled public final String id;
        @AuraEnabled public final String name;
        @AuraEnabled public final String email;
        @AuraEnabled public final String phone;
        @AuraEnabled public final String profile;

        public UserPermissionAssignmentInfo(
            String id,
            String name,
            String email,
            String phone,
            String profile
        ) {
            this.id = id;
            this.name = name;
            this.email = email;
            this.phone = phone;
            this.profile = profile;
        }
    }
}
