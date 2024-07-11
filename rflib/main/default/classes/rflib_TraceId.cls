/*
 * Copyright (c) 2021 Johannes Fischer <fischer.jh@gmail.com>
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
 * @group Integration
 * @description Value holder for the Trace ID to be used in log statements and 
                when sending HTTP requests using rflib_HttpRequest.
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_TraceId {
    
    public static String value {
        get {
            switch on rflib_GlobalSettings.traceIdValueFormatOrDefault.toUpperCase() {
                when 'REQUEST_ID' {
                    return Request.getCurrent().getRequestId();
                }
                when 'USER15_REQUEST_ID' {
                    return Id.valueOf(UserInfo.getUserId()).to15() + '|' + Request.getCurrent().getRequestId();
                }
                when else {
                    return UserInfo.getUserId() + '|' + Request.getCurrent().getRequestId();
                }
            }
        }
    }
    
    @TestVisible
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_TraceId() { }
}
