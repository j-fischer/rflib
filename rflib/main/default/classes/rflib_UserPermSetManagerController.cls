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
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_UserPermSetManagerController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_UserPermSetManagerController');

    @AuraEnabled(cacheable=true)
    public static List<PermissionSetDTO> getAssignedPermissionSets(String alias) {
        try {
            LOGGER.info('getPermissionSets({0}) invoked', new Object[]{alias});
            List<PermissionSetAssignment> psaList = [
                SELECT Id, PermissionSet.Name, PermissionSet.Label
                FROM PermissionSetAssignment
                WHERE Assignee.Alias = :alias
                ORDER BY PermissionSet.Label ASC
            ];
            
            List<PermissionSetDTO> result = new List<PermissionSetDTO>();
            for (PermissionSetAssignment psa : psaList) {
                result.add(new PermissionSetDTO(psa.Id, psa.PermissionSet.Name, psa.PermissionSet.Label));
            }
            
            return result;
        } catch (Exception ex) {
            LOGGER.error('Error in getPermissionSets method for alias: ' + alias, ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PermissionSet> getAllPermissionSets() {
        try {
            LOGGER.info('getAllPermissionSets() invoked');
            return [SELECT Id, Name, Label FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Label];
        } catch (Exception ex) {
            LOGGER.error('Error in getAllPermissionSets method', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void assignPermissionSet(Id permissionSetId, String alias) {
        try {
            User user = [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = permissionSetId
            );
            insert psa;
        } catch (Exception ex) {
            LOGGER.error('Error in assignPermissionSet method for alias: ' + alias + ' and permissionSetId: ' + permissionSetId, ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePermissionSetAssignment(Id permissionSetAssignmentId) {
        try {
            PermissionSetAssignment psa = [SELECT Id FROM PermissionSetAssignment WHERE Id = :permissionSetAssignmentId LIMIT 1];
            delete psa;
        } catch (Exception ex) {
            LOGGER.error('Error in deletePermissionSetAssignment method for permissionSetAssignmentId: ' + permissionSetAssignmentId, ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

    private static Boolean isNotASalesforceId(String stringToValidate) {
        try {
            Id.valueOf(stringToValidate);
            return false;
        } catch (Exception ex) {
            return true;
        }
    }

    public class PermissionSetDTO {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String Label { get; set; }
        
        public PermissionSetDTO(Id Id, String Name, String Label) {
            this.Id = Id;
            this.Name = Name;
            this.Label = Label;
        }
    }
}
