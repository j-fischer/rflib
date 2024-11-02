public with sharing class rflib_PublicGroupMemberManagerController {

    private static rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_PublicGroupMemberManagerController');

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
            LOGGER.error('Error fetching group members: ' + ex.getMessage());
            throw new AuraHandledException('Error fetching group members: ' + ex.getMessage());
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
                throw new AuraHandledException('User is already a member of the group.');
            }
        } catch (Exception e) {
            LOGGER.error('Error adding user to group: ' + e.getMessage());
            throw new AuraHandledException('Error adding user to group: ' + e.getMessage());
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
                throw new AuraHandledException('User is not a member of the group.');
            }
        } catch (Exception e) {
            LOGGER.error('Error removing user from group: ' + e.getMessage());
            throw new AuraHandledException('Error removing user from group: ' + e.getMessage());
        }
    }
}
