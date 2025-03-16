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
public class rflib_MockDmlExecutor implements rflib_DmlExecutor {
    public List<SObject> capturedRecords;

    private final List<List<Database.SaveResult>> expectedSaveResults = new List<List<Database.SaveResult>>();
    private final List<List<Object>> expectedDeleteResults = new List<List<Object>>();

    private Integer invocationCount = 0;
    private Exception exceptionToThrow;

    public rflib_MockDmlExecutor(List<Database.SaveResult> saveResults) {
        this.expectedSaveResults.add(saveResults);
    }

    public rflib_MockDmlExecutor(List<Database.DeleteResult> deleteResults) {
        this.expectedDeleteResults.add(deleteResults);
    }

    public rflib_MockDmlExecutor(Exception ex) {
        this.exceptionToThrow = ex;
    }
    
    public void onConsecutiveCall(List<Database.SaveResult> saveResults) {
        this.expectedSaveResults.add(saveResults);
    }

    public void onConsecutiveCall(List<Database.DeleteResult> deleteResults) {
        this.expectedDeleteResults.add(deleteResults);
    }

    public Integer getInvocationCount() {
        return invocationCount;
    }

    public List<Database.SaveResult> insertImmediate(List<SObject> sobjects) {
        if (exceptionToThrow != null) {
            throw exceptionToThrow;
        }
        this.capturedRecords = sobjects;
        return expectedSaveResults.get(invocationCount++);
    }

    public List<Database.DeleteResult> deleteImmediate(List<SObject> sobjects) {
        if (exceptionToThrow != null) {
            throw exceptionToThrow;
        }
        this.capturedRecords = sobjects;
        return (List<Database.DeleteResult>) expectedDeleteResults.get(invocationCount++);
    }
}
