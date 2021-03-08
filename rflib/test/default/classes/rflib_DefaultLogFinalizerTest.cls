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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_DefaultLogFinalizerTest {

    private static final rflib_MockLogger LOGGER_MOCK = new rflib_MockLogger();

    @IsTest
    private static void testSuccess() {
        rflib_DefaultLogFinalizer logFinalizer = new rflib_DefaultLogFinalizer();

        logFinalizer.setLogger(LOGGER_MOCK);
        
        FinalizerContext ctx = new TestFinalizerContext(ParentJobResult.SUCCESS);
        logFinalizer.execute(ctx);

        System.assertEquals(1, LOGGER_MOCK.logDetails.size());
        System.assertEquals(rflib_LogLevel.INFO, LOGGER_MOCK.logDetails.get(0).logLevel);
        System.assert(LOGGER_MOCK.logDetails.get(0).message.contains('completed successfully'));
        System.assert(LOGGER_MOCK.batchedEventsPublished);
    }

    @IsTest
    private static void testFailure() {
        rflib_DefaultLogFinalizer logFinalizer = new rflib_DefaultLogFinalizer();

        logFinalizer.setLogger(LOGGER_MOCK);

        FinalizerContext ctx = new TestFinalizerContext(ParentJobResult.UNHANDLED_EXCEPTION); 
        logFinalizer.execute(ctx);

        System.assertEquals(1, LOGGER_MOCK.logDetails.size());
        System.assertEquals(rflib_LogLevel.FATAL, LOGGER_MOCK.logDetails.get(0).logLevel);
        System.assert(LOGGER_MOCK.logDetails.get(0).message.contains('failed'));
        System.assert(LOGGER_MOCK.batchedEventsPublished);
    }

    public class TestFinalizerContext implements FinalizerContext {

        private final ParentJobResult jobResult;

        public TestFinalizerContext(ParentJobResult jobResult) {
            this.jobResult = jobResult;
        }

        public String getRequestId() {
            return 'req123';
        }

        public Id getAsyncApexJobId() {
            return null;
        }

        public ParentJobResult getResult() {
            return jobResult;
        }

        public Exception getException() {
            return new TestException();
        }
    }

    public class TestException extends Exception { }
}
