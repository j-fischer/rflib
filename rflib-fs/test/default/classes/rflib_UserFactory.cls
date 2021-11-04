/*
 * Copyright (c) 2021 Johannes Fischer <fischer.jh@gmail.com>
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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_UserFactory {
    
    public static User insertAndRetrieve(String firstName, String lastName, String profileName) {
        User u = new Builder(firstName, lastName, profileName).persist();
        return [SELECT Firstname, Lastname, Username, Email FROM User WHERE Id = :u.Id];
    }

    public static User insertWithCustomPermissionAndRetrieve(String firstName, String lastName, String profileName, String customPermissionApiName) {
        User u = new Builder(firstName, lastName, profileName).withCustomPermission(customPermissionApiName).persistWithPermissions();
        return [SELECT Firstname, Lastname, Username, Email FROM User WHERE Id = :u.Id];
    }

    private rflib_UserFactory() { }

    public class Builder {

        private final SObject record;
        private final Set<String> assignedCustomPermissions = new Set<String>();

        public Builder(String firstName, String lastName, String profileName) {
            String email = firstName + '.' + lastName + '@rflib.com';
            record = new User(
                Firstname = firstName,
                Lastname = lastName,
                Username = email,
                Email = email,
                Alias = 'rflibusr', 
                ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id,
                TimeZoneSidKey = 'GMT',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LocaleSidKey = 'en_US'
            );
        }

        public Builder withField(String name, Object value) {
            record.put(name, value);
            return this;
        }

        public Builder withCustomPermission(String apiName) {
            assignedCustomPermissions.add(apiName);
            return this;
        }

        public User create() {
            return (User) record;
        }

        public User persist() {
            insert record;
            return (User) record;
        }

        public User persistWithPermissions() {
            User userRecord = (User) record;
            insert userRecord;

            PermissionSet permissionSet = new PermissionSet(
                Name = 'rflib' + userRecord.Firstname + userRecord.Lastname, 
                Label = userRecord.Username
            );

            insert permissionSet;

            insert new PermissionSetAssignment(
                PermissionSetId = permissionSet.Id, 
                AssigneeId = record.Id
            );

            List<SetupEntityAccess> customPermissionAssignments = new List<SetupEntityAccess>();
            for (CustomPermission cp : getCustomPermissions(assignedCustomPermissions)) {
                customPermissionAssignments.add(new SetupEntityAccess(
                    ParentId = permissionSet.Id, 
                    SetupEntityId = cp.Id
                ));
            }

            insert customPermissionAssignments;

            return userRecord;
        }

        private List<CustomPermission> getCustomPermissions(Set<String> apiNames) {
            List<CustomPermission> result = [
                SELECT Id
                FROM CustomPermission
                WHERE DeveloperName IN :apiNames
            ];

            return result;
        }
    }
}
