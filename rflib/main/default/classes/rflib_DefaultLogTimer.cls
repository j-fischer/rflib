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
 * 3. Neither the name of mosquitto nor the names of its
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
 * @description Default rflib_LogTimer implementation, which is based on the configuration
 *              stored in the Logger Settings Custom Setting object.  
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public without sharing class rflib_DefaultLogTimer implements rflib_LogTimer {
    
    private rflib_Logger logger;
    private rflib_LogLevel logLevel;
    private Integer threshold;
    private String message;
    private Long startTime;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void start(rflib_Logger logger, rflib_LogLevel logLevel, Integer threshold, String message) {
        if (this.logger != null) {
            throw new rflib_InvalidStateException('Timer has already been started');
        }
        
        this.logger = logger;
        this.logLevel = logLevel;
        this.threshold = threshold;
        this.message = message;

        this.startTime = Datetime.now().getTime();
    }

    public void done() {
        if (this.logger == null) {
            throw new rflib_InvalidStateException('Timer has not been started');
        }

        Long endTime = DateTime.now().getTime();
        Long duration = endTime - startTime;

        if (duration > threshold) {
            logMessage(duration, logLevel);
        } else {
            logMessage(duration, rflib_LogLevel.TRACE);
        }
    }

    private void logMessage(Long duration, rflib_LogLevel logLevel) {
        String fullMessage = message + ' took a total of {0}ms (threshold={1}ms).';
        Object[] args = new Object[] { duration, threshold };

        switch on logLevel.toString() {
            when 'TRACE' {
                logger.trace(fullMessage, args);
            }

            when 'DEBUG' {
                logger.debug(fullMessage, args);
            }

            when 'INFO' {
                logger.info(fullMessage, args);
            }

            when 'WARN' {
                logger.warn(fullMessage, args);
            }

            when 'ERROR' {
                logger.error(fullMessage, args);
            }

            when 'FATAL' {
                logger.fatal(fullMessage, args);
            }
        }
    }
}
