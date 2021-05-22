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
    public static QueryResult getFieldLevelSecurityForAllProfiles(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead 
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
    public static QueryResult getFieldLevelSecurityForAllPermissionSets(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead 
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
    public static QueryResult getObjectLevelSecurityForAllProfiles(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, PermissionsRead, PermissionsCreate, 
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
    public static QueryResult getObjectLevelSecurityForAllPermissionSets(){
        try {
            return convertToPermissionInfo([
                SELECT Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, 
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

    private static QueryResult convertToPermissionInfo(List<FieldPermissions> fieldPermissionsList) {
        QueryResult result = new QueryResult();
        for (FieldPermissions fp : fieldPermissionsList) {
            result.records.add(new PermissionInfo(fp));
        }
        return result;
    }

    private static QueryResult convertToPermissionInfo(List<ObjectPermissions> objectPermissionsList) {
        QueryResult result = new QueryResult();
        for (ObjectPermissions op : objectPermissionsList) {
            result.records.add(new PermissionInfo(op));
        }
        return result;
    }

    public class QueryResult {
        @AuraEnabled public List<PermissionInfo> records = new List<PermissionInfo>();
        @AuraEnabled public String nextRecordsUrl;
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
}
