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
@SuppressWarnings('PMD.ExcessivePublicCount,PMD.ClassNamingConventions')
public class rflib_MockLogger implements rflib_Logger {
    
    public Integer logCacheSize;
    public Boolean isLogMaskingEnabled;
    public rflib_LogLevel reportingLogLevel;
    public rflib_LogLevel flushLogCacheLevel;
    public rflib_LogLevel batchReportingLogLevel;
    public rflib_LogLevel systemDebugLevel;
    public rflib_LogLevel generalLogLevel;
    public String platformInfo;

    public Boolean logsPrinted = false;
    public Boolean logEventsPublished = false;
    public Boolean batchedEventsPublished = false;

    public final List<LogDetails> logDetails = new List<LogDetails>();

    public void setLogCacheSize(Integer newSize) {
        this.logCacheSize = newSize;
    }

    public void setReportingLogLevel(rflib_LogLevel newLevel) {
        this.reportingLogLevel = newLevel;
    }

    public void setFlushLogCacheLevel(rflib_LogLevel newLevel) {
        this.flushLogCacheLevel = newLevel;
    }

    public void setBatchReportingLogLevel(rflib_LogLevel newLevel) {
        this.batchReportingLogLevel = newLevel;
    }

    public void setSystemDebugLevel(rflib_LogLevel newLevel) {
        this.systemDebugLevel = newLevel;
    }

    public void setGeneralLogLevel(rflib_LogLevel newLevel) {
        this.generalLogLevel = newLevel;
    }

    public void setLogMaskingState(Boolean isEnabled) {
        this.isLogMaskingEnabled = isEnabled;
    }

    public void setPlatformInfo(String platformInfo) {
        this.platformInfo = platformInfo;
    }

    public void trace(String message) {
        trace(message, null);
    }

    public void trace(String message, Object[] args) {
        addLogDetails(rflib_LogLevel.TRACE, message, args);
    }
    
    public void debug(String message) {
        debug(message, null);
    }

    public void debug(String message, Object[] args) {
        addLogDetails(rflib_LogLevel.DEBUG, message, args);
    }

    public void info(String message) {
        info(message, null);
    }

    public void info(String message, Object[] args) {
        addLogDetails(rflib_LogLevel.INFO, message, args);
    }

    public void warn(String message) {
        warn(message, null);
    }

    public void warn(String message, Object[] args) {
        addLogDetails(rflib_LogLevel.WARN, message, args);
    }

    public void error(String message) {
        error(message, null, null);
    }

    public void error(String message, Exception ex) {
        error(message, null, ex);
    }

    public void error(String message, Object[] args) {
        error(message, args, null);
    }

    public void error(String message, Object[] args, Exception ex) {
        addLogDetails(rflib_LogLevel.ERROR, message, args, ex);
    }

    public void fatal(String message) {
        fatal(message, null, null);
    }

    public void fatal(String message, Exception ex) {
        fatal(message, null, ex);
    }

    public void fatal(String message, Object[] args) {
        fatal(message, args, null);
    }

    public void fatal(String message, Object[] args, Exception ex) {
        addLogDetails(rflib_LogLevel.FATAL, message, args, ex);
    }

    private void addLogDetails(rflib_LogLevel logLevel, String message, Object[] args) {
        addLogDetails(logLevel, message, args, null);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void addLogDetails(rflib_LogLevel logLevel, String message, Object[] args, Exception ex) {
        logDetails.add(new LogDetails(logLevel, message, args, ex));
    }
    
    public void printLogs() {
        logsPrinted = true;
    }
    
    public void reportLogs() {
        logEventsPublished = true;
    }
    
    public void publishBatchedLogEvents() {
        batchedEventsPublished = true;
    }

    public class LogDetails {
        public final rflib_LogLevel logLevel;
        public final String message;
        public final Object[] args;
        public final Exception ex; 
        
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public LogDetails(rflib_LogLevel logLevel, String message, Object[] args, Exception ex) {
            this.logLevel = logLevel;
            this.message = message;
            this.args = args;
            this.ex = ex;
        }
        
        public override String toString() {
            return String.format('{0}|{1}|{2}', new Object[] { logLevel, String.format(message, args), ex});
        }
    }
}
