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
    
    @IsTest
    @SuppressWarnings('PMD.ClassNamingConventions')
    private static void testGetFieldLevelSecurityForAllProfiles_Success() {
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;
        
        System.assert(records.size() > 0);

        rflib_PermissionsExplorerController.PermissionInfo info = records.get(0);
        System.assertEquals('Profile', info.securityType);
        System.assertNotEquals(null, info.PermissionsRead);
        System.assertNotEquals(null, info.PermissionsEdit);
    }

    @IsTest
    @SuppressWarnings('PMD.ClassNamingConventions')
    private static void testGetFieldLevelSecurityForAllPermissionSets_Success() {
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;

        System.assertEquals([SELECT Parent.Label, Parent.IsOwnedByProfile, SobjectType, Field, PermissionsEdit, PermissionsRead 
        FROM FieldPermissions 
        WHERE Parent.IsOwnedByProfile = false 
        ORDER BY Parent.Profile.Name, Parent.Label, SobjectType, Field
        LIMIT 50000].size(), records.size());
    }

    @IsTest
    @SuppressWarnings('PMD.ClassNamingConventions')
    private static void testGetObjectLevelSecurityForAllProfiles_Success() {
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;

        System.assert(records.size() > 0);

        rflib_PermissionsExplorerController.PermissionInfo info = records.get(0);
        System.assertEquals('Profile', info.securityType);
        System.assertNotEquals(null, info.PermissionsRead);
        System.assertNotEquals(null, info.PermissionsEdit);
        System.assertNotEquals(null, info.PermissionsCreate);
        System.assertNotEquals(null, info.PermissionsDelete);
    }

    @IsTest
    @SuppressWarnings('PMD.ClassNamingConventions')
    private static void testGetObjectLevelSecurityForAllPermissionSets_Success() {
        rflib_PermissionsExplorerController.QueryResult result = rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets(null);
        List<rflib_PermissionsExplorerController.PermissionInfo> records = result.records;

        System.assert(records.size() > 0);
        
        rflib_PermissionsExplorerController.PermissionInfo info = records.get(0);
        System.assertEquals('PermissionSet', records.get(0).securityType);
        System.assertNotEquals(null, info.PermissionsRead);
        System.assertNotEquals(null, info.PermissionsEdit);
        System.assertNotEquals(null, info.PermissionsCreate);
        System.assertNotEquals(null, info.PermissionsDelete);
    }
}
