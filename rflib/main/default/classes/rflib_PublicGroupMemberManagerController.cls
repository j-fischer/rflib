public without sharing class rflib_PublicGroupMemberManagerController {

    private static rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_PublicGroupMemberManagerController');

    @AuraEnabled(cacheable=true)
    public static Boolean canUserModifyGroupMemberships() {
        try {
            LOGGER.info('canUserModifyGroupMemberships() invoked');
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType groupMemberType = schemaMap.get('GroupMember');
            Boolean isCreateable = groupMemberType.getDescribe().isCreateable();
            
            LOGGER.info('GroupMember is isCreateable: {0}', new List<Object>{ isCreateable });
            return isCreateable;
        } catch (Exception ex) {
            LOGGER.error('Error in canUserModifyGroupMemberships: {0}', new List<Object>{ ex.getMessage() });
            throw rflib_ControllerUtil.createAuraHandledException('An error occurred while checking user permissions: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<User> getGroupMembers(String groupApiName) {
        LOGGER.info('Fetching group members for group: ' + groupApiName);
        try {
            Group targetGroup = [SELECT Id FROM Group WHERE DeveloperName = :groupApiName AND Type = 'Regular' LIMIT 1];

            List<User> users = [
                SELECT Id, Name, Username, Email
                FROM User
                WHERE Id IN (
                    SELECT UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId = :targetGroup.Id
                )
            ];
            
            LOGGER.info('Group members fetched successfully: ' + JSON.serialize(users));
            return users;
        } catch (Exception ex) {
            LOGGER.error('Error fetching group members: ' + ex.getMessage(), ex);
            throw rflib_ControllerUtil.createAuraHandledException('Error fetching group members: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void addUserToGroup(String groupApiName, Id userId) {
        LOGGER.info('Adding user ' + userId + ' to group: ' + groupApiName);
        try {
            Group targetGroup = [SELECT Id FROM Group WHERE DeveloperName = :groupApiName AND Type = 'Regular' LIMIT 1];
            Integer existingMembers = [
                SELECT COUNT() 
                FROM GroupMember 
                WHERE GroupId = :targetGroup.Id AND UserOrGroupId = :userId
            ];
            if (existingMembers == 0) {
                GroupMember gm = new GroupMember(GroupId = targetGroup.Id, UserOrGroupId = userId);
                insert gm;
                LOGGER.info('User ' + userId + ' added to group successfully.');
            } else {
                LOGGER.warn('User ' + userId + ' is already a member of the group.');
                throw rflib_ControllerUtil.createAuraHandledException('User is already a member of the group.');
            }
        } catch (Exception ex) {
            LOGGER.error('Error adding user to group: ' + ex.getMessage(), ex);
            throw rflib_ControllerUtil.createAuraHandledException('Error adding user to group: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void removeUserFromGroup(String groupApiName, Id userId) {
        LOGGER.info('Removing user ' + userId + ' from group: ' + groupApiName);
        try {
            Group targetGroup = [SELECT Id FROM Group WHERE DeveloperName = :groupApiName AND Type = 'Regular' LIMIT 1];
            List<GroupMember> membersToDelete = [
                SELECT Id 
                FROM GroupMember 
                WHERE GroupId = :targetGroup.Id AND UserOrGroupId = :userId
            ];
            if (!membersToDelete.isEmpty()) {
                delete membersToDelete;
                LOGGER.info('User ' + userId + ' removed from group successfully.');
            } else {
                LOGGER.warn('User ' + userId + ' is not a member of the group.');
                throw rflib_ControllerUtil.createAuraHandledException('User is not a member of the group.');
            }
        } catch (Exception ex) {
            LOGGER.error('Error removing user from group: ' + ex.getMessage(), ex);
            throw rflib_ControllerUtil.createAuraHandledException('Error removing user from group: ' + ex.getMessage());
        }
    }
}
