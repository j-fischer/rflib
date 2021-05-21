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

    @AuraEnabled(cacheable = true)
    public static List<PermissionInfo> getFieldLevelSecurityForAllProfiles(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead 
                FROM FieldPermissions 
                WHERE Parent.IsOwnedByProfile = true 
                ORDER BY Parent.Profile.Name, Parent.Label, SobjectType, Field
                LIMIT 50000
            ]);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all profiles', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<PermissionInfo> getFieldLevelSecurityForAllPermissionSets(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Label, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead 
                FROM FieldPermissions 
                WHERE Parent.IsOwnedByProfile = false 
                ORDER BY Parent.Profile.Name, Parent.Label, SobjectType, Field
                LIMIT 50000
            ]);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve field level security for all permission sets', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<PermissionInfo> getObjectLevelSecurityForAllProfiles(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, PermissionsRead, PermissionsCreate, 
                    PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
                FROM ObjectPermissions 
                WHERE Parent.IsOwnedByProfile = true 
                ORDER BY Parent.Profile.Name, Parent.Label, SobjectType
                LIMIT 50000
            ]);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all profiles', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<PermissionInfo> getObjectLevelSecurityForAllPermissionSets(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Label, Parent.IsOwnedByProfile, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, 
                    PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
                FROM ObjectPermissions 
                WHERE Parent.IsOwnedByProfile = false 
                ORDER BY Parent.Profile.Name, Parent.Label, SobjectType
                LIMIT 50000
            ]);
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve object level security for all permission sets', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static List<PermissionInfo> convertToPermissionInfo(List<FieldPermissions> fieldPermissionsList) {
        List<PermissionInfo> result = new List<PermissionInfo>();
        for (FieldPermissions fp : fieldPermissionsList) {
            result.add(new PermissionInfo(fp));
        }
        return result;
    }

    private static List<PermissionInfo> convertToPermissionInfo(List<ObjectPermissions> objectPermissionsList) {
        List<PermissionInfo> result = new List<PermissionInfo>();
        for (ObjectPermissions op : objectPermissionsList) {
            result.add(new PermissionInfo(op));
        }
        return result;
    }

    public class PermissionInfo {
        @AuraEnabled public String securityType;
        @AuraEnabled public String securityObjectName;
        @AuraEnabled public String sObjectType;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean permissionEdit;
        @AuraEnabled public Boolean permissionRead;
        @AuraEnabled public Boolean permissionCreate;
        @AuraEnabled public Boolean permissionDelete;
        @AuraEnabled public Boolean permissionViewAll;
        @AuraEnabled public Boolean permissionModifyAll;

        public PermissionInfo(FieldPermissions record) {
            this.securityType = record.Parent.IsOwnedByProfile ? 'Profile' : 'PermissionSet';
            this.securityObjectName =  record.Parent.IsOwnedByProfile ? record.Parent.Profile.Name : record.Parent.Label;
            this.sObjectType = record.SObjectType;
            this.fieldName = record.Field.substringAfter('.');
            this.permissionEdit = record.PermissionsEdit;
            this.permissionRead = record.PermissionsRead;
        }

        
        public PermissionInfo(ObjectPermissions record) {
            this.securityType = record.Parent.IsOwnedByProfile ? 'Profile' : 'PermissionSet';
            this.securityObjectName =  record.Parent.IsOwnedByProfile ? record.Parent.Profile.Name : record.Parent.Label;
            this.sObjectType = record.SObjectType;
            this.permissionEdit = record.PermissionsEdit;
            this.permissionRead = record.PermissionsRead;
            this.permissionCreate = record.PermissionsCreate;
            this.permissionDelete = record.PermissionsDelete;
            this.permissionViewAll = record.PermissionsViewAllRecords;
            this.permissionModifyAll = record.PermissionsModifyAllRecords;
        }
    }
}
