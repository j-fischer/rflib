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
 * @description Value holder for a Salesforce platform diagnostic event that has been normalized so it
 *              can be reported through RFLIB's regular log event pipeline. Created by the adapters in
 *              this package and consumed by `rflib_DiagnosticEventPublisher`.
 *
 *              There is deliberately no log level on this type. Salesforce publishes the diagnostic
 *              events RFLIB subscribes to only after a unit of work has already failed, so the severity
 *              is a constant owned by the publisher, not a per-event decision.
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_DiagnosticEvent {

    /**
     * @description The API name of the platform event this diagnostic originated from. Reported as the
     *              log event's `Context__c` so the Log Monitor can filter by diagnostic source.
     */
    public String context;

    /**
     * @description The Salesforce Request ID of the transaction that failed, used to correlate this
     *              diagnostic with debug logs and other log statements of the same transaction.
     */
    public String requestId;

    /**
     * @description The human readable description of what failed.
     */
    public String message;

    /**
     * @description The stacktrace of the failure, if the source event provides one.
     */
    public String stacktrace;

    /**
     * @description The remaining fields of the source event. Serialized into the log event's
     *              `Platform_Info__c` where `rflib_PlatformInfoTransformer` flattens them into
     *              individually indexable attributes for OpenTelemetry and Application Insights.
     */
    public Map<String, Object> attributes;

    /**
     * @description Create a new diagnostic event.
     * @param context   The API name of the source platform event.
     * @param requestId The Request ID of the failed transaction.
     * @param message   The description of what failed.
     */
    public rflib_DiagnosticEvent(String context, String requestId, String message) {
        this.context = context;
        this.requestId = requestId;
        this.message = message;
        this.attributes = new Map<String, Object>();
    }
}
