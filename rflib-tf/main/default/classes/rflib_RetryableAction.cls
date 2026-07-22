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
/**
 * @group RetryableAction
 * @description Read-only data object representing a single Retryable Action. It carries the custom and
 *              standard fields of the `rflib_Retryable_Action__e` and `rflib_Retryable_Action_After_Commit__e`
 *              Platform Events, decoupling handler implementations from the concrete event type. Property
 *              names match the event field API names; Apex does not allow consecutive underscores in
 *              identifiers, so the `__c` suffix is omitted for custom fields.
 */
@SuppressWarnings('PMD.ClassNamingConventions,PMD.PropertyNamingConventions,PMD.FieldNamingConventions')
public inherited sharing class rflib_RetryableAction {

    public String Action { get; private set; }
    public String Record_ID { get; private set; }
    public String Additional_Record_ID { get; private set; }
    public String Additional_Details { get; private set; }
    public String ReplayId { get; private set; }
    public String EventUuid { get; private set; }
    public SObject event { get; private set; }

    public rflib_RetryableAction(SObject evt) {
        this.Action = (String) evt.get('Action__c');
        this.Record_ID = (String) evt.get('Record_ID__c');
        this.Additional_Record_ID = (String) evt.get('Additional_Record_ID__c');
        this.Additional_Details = (String) evt.get('Additional_Details__c');
        this.ReplayId = (String) evt.get('ReplayId');
        this.EventUuid = (String) evt.get('EventUuid');
        this.event = evt;
    }

    public static List<rflib_RetryableAction> fromEvents(List<SObject> events) {
        List<rflib_RetryableAction> result = new List<rflib_RetryableAction>();
        for (SObject evt : events) {
            result.add(new rflib_RetryableAction(evt));
        }
        return result;
    }
}
