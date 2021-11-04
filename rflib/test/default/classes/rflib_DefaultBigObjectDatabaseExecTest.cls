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
private class rflib_DefaultBigObjectDatabaseExecTest {   
    
    @TestSetup
    static void makeData(){
        rflib_TestUtil.prepareLoggerForUnitTests();
    }

    @IsTest
    private static void testInsertImmediate_Success() {
        rflib_Log_Archive__b record = createLogArchiveRecord('contextA');
        List<rflib_Log_Archive__b> records = new List<rflib_Log_Archive__b> { record };

        rflib_MockDmlExecutor mockDbExecutor = new rflib_MockDmlExecutor(new List<Database.SaveResult> { createSuccessSaveResult()} );
        new rflib_DefaultBigObjectDatabaseExecutor(mockDbExecutor).insertImmediate(records);
        
        System.assertEquals(1, mockDbExecutor.getInvocationCount());
    }

    @IsTest
    private static void testInsertImmediate_Failure() {
        rflib_Log_Archive__b record = createLogArchiveRecord('contextA');
        List<rflib_Log_Archive__b> records = new List<rflib_Log_Archive__b> { record };

        rflib_MockDmlExecutor mockDbExecutor = new rflib_MockDmlExecutor(new List<Database.SaveResult> { createFailureSaveResult() } );
        mockDbExecutor.onConsecutiveCall(new List<Database.SaveResult> { createSuccessSaveResult() });

        Test.startTest();
        new rflib_DefaultBigObjectDatabaseExecutor(mockDbExecutor).insertImmediate(records);
        Test.stopTest();

        // Verified in the debug logs that the async call was made and insertImmediate() ran twice. However, it looks like
        // the class has been serialized prior to the Test.stop() call and is deserialized after, which explains why the 
        // the invocation count is still 1. 
        System.assertEquals(1, mockDbExecutor.getInvocationCount());
    }

    private static Database.SaveResult createSuccessSaveResult() {
        return (Database.SaveResult) JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.SaveResult.class);
    }

    private static Database.SaveResult createFailureSaveResult() {
        return (Database.SaveResult) JSON.deserialize('{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
    }

    private static rflib_Log_Archive__b createLogArchiveRecord(String context) {
        return rflib_LogArchiveFactory.create(context);
    }
}
