/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_RetryableActionTest {

    @IsTest
    public static void testConstructor_RetryableActionEvent() {
        rflib_Retryable_Action__e evt = new rflib_Retryable_Action__e(
            Action__c = 'Action_One',
            Record_ID__c = 'recId1',
            Additional_Record_ID__c = 'recId2',
            Additional_Details__c = 'some details'
        );

        rflib_RetryableAction action = new rflib_RetryableAction(evt);

        Assert.areEqual('Action_One', action.Action);
        Assert.areEqual('recId1', action.Record_ID);
        Assert.areEqual('recId2', action.Additional_Record_ID);
        Assert.areEqual('some details', action.Additional_Details);
        Assert.isNull(action.ReplayId);
        Assert.isNull(action.EventUuid);
        Assert.areEqual(evt, action.event);
    }

    @IsTest
    public static void testConstructor_RetryableActionAfterCommitEvent() {
        rflib_Retryable_Action_After_Commit__e evt = new rflib_Retryable_Action_After_Commit__e(
            Action__c = 'Action_Two',
            Record_ID__c = 'recId3',
            Additional_Record_ID__c = 'recId4',
            Additional_Details__c = 'more details'
        );

        rflib_RetryableAction action = new rflib_RetryableAction(evt);

        Assert.areEqual('Action_Two', action.Action);
        Assert.areEqual('recId3', action.Record_ID);
        Assert.areEqual('recId4', action.Additional_Record_ID);
        Assert.areEqual('more details', action.Additional_Details);
        Assert.areEqual(evt, action.event);
    }

    @IsTest
    public static void testFromEvents() {
        List<SObject> events = new List<SObject> {
            new rflib_Retryable_Action__e(
                Action__c = 'Action_One',
                Record_ID__c = 'recId1'
            ),
            new rflib_Retryable_Action_After_Commit__e(
                Action__c = 'Action_Two',
                Record_ID__c = 'recId2'
            )
        };

        List<rflib_RetryableAction> actions = rflib_RetryableAction.fromEvents(events);

        Assert.areEqual(2, actions.size());
        Assert.areEqual('recId1', actions.get(0).Record_ID);
        Assert.isInstanceOfType(actions.get(0).event, rflib_Retryable_Action__e.class);
        Assert.areEqual('recId2', actions.get(1).Record_ID);
        Assert.isInstanceOfType(actions.get(1).event, rflib_Retryable_Action_After_Commit__e.class);
    }
}
