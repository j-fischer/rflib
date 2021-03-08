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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_MockLoggerFactory implements rflib_LoggerFactory {

    public final DebugLogCapture debugLogCapture = new DebugLogCapture();
    public final EventCapture eventCapture = new EventCapture();

    private final rflib_LogLevel systemDebugLogLevel;

    public rflib_MockLoggerFactory() {
       this(null);
    }

    public rflib_MockLoggerFactory(rflib_LogLevel systemDebugLogLevel) {
       this.systemDebugLogLevel = systemDebugLogLevel;
    }

    public rflib_Logger createLogger(String context) {
        rflib_DefaultLogger result = new rflib_DefaultLogger(
            eventCapture,
            debugLogCapture,
            context
        );

        if (systemDebugLogLevel != null) {
            result.setSystemDebugLevel(rflib_LogLevel.DEBUG);
        }
        return result;
    }

    public rflib_Logger createBatchedLogger(String context) {
        rflib_DefaultLogger result = new rflib_DefaultLogger(
            eventCapture,
            debugLogCapture,
            context
        );

        if (systemDebugLogLevel != null) {
            result.setSystemDebugLevel(rflib_LogLevel.DEBUG);
        }
        return result;
    }


    public class DebugLogCapture implements rflib_DefaultLogger.DebugLogger {
        public final List<String> capturedLogMessages = new List<String>();

        public void debug(LoggingLevel level, String message) {
            capturedLogMessages.add(message);
        }

        public void clearCapturedLogs() {
            capturedLogMessages.clear();
        }

        public Boolean doesNotContainInAnyMessage(String substring) {
          for (String message : capturedLogMessages) {
            if (message.contains(substring)) {
              System.debug('Actual messages:\n' + String.join(capturedLogMessages, '\n'));
              return false;
            }
          }

          return true;
        }

        public Boolean containsInAnyMessage(String substring) {
          for (String message : capturedLogMessages) {
            if (message.contains(substring)) {
              return true;
            }
          }

          System.debug('Actual messages:\n' + String.join(capturedLogMessages, '\n'));
          return false;
        }
    }

    public class EventCapture implements rflib_DefaultLogger.EventPublisher {
        private rflib_Log_Event__e capturedEvent;

        public void publish(SObject event) {
          capturedEvent = (rflib_Log_Event__e) event;
        }

        public Boolean eventHasNotBeenPublished() {
          return capturedEvent == null;
        }

        public Boolean eventHasBeenPublished() {
          return capturedEvent != null;
        }

        public Boolean doesNotContainInAnyMessage(String substring) {
          Boolean result = capturedEvent.Log_Messages__c.contains(substring);
          if (result) {
            System.debug('Actual event message:\n' + capturedEvent.Log_Messages__c);
          }
          return result == false;
        }

        public Boolean containsInAnyMessage(String substring) {
          Boolean result = capturedEvent.Log_Messages__c.contains(substring);
          if (!result) {
            System.debug('Actual event message:\n' + capturedEvent.Log_Messages__c);
          }
          return result;
        }
    }
}
