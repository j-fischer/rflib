/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
 * @group Logger
 * @description A batch that always fails, used to make Salesforce publish a real
 *              `BatchApexErrorEvent`. Salesforce is the only publisher of that event and Apex cannot
 *              insert it, so running this batch is the only way a test can exercise the subscription
 *              in `rflib_BatchApexErrorEventTrigger`.
 *
 *              `Database.RaisesPlatformEvents` is what makes Salesforce publish the event for this
 *              class; batch classes that do not declare it never raise one.
 */
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_MockFailingBatch implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    public static final String FAILURE_MESSAGE = 'Deliberate failure to raise a BatchApexErrorEvent';

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {
        throw new rflib_InvalidStateException(FAILURE_MESSAGE);
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext ctx) { }
}
