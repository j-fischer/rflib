/*
 * Copyright (c) 2022 Johannes Fischer <fischer.jh@gmail.com>
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
import { Context, Logger } from "sf-fx-sdk-nodejs";

/**
 * Represents the configuration of the RFLIB Logger instance. Use this object 
 * when overriding the configuration retrieved from the server instance. 
 * @property stackSize (Optional) The number of log messages to be stored in the log stack.
 * @property computeLogLevel (Optional) The minimum log level for messages to be forwarded to the Salesforce Function logger instance.
 * @property serverLogLevel (Optional) The minimum log level for messages to be submitted as a platform event.
 */
export declare type LoggerConfig = {
    readonly stackSize?: number;
    readonly computeLogLevel?: string;
    readonly serverLogLevel?: string;
};

/**
 * Represents a Logger instance of RFLIB. 
 */
export interface RflibLogger {
    /**
     * Set new configuration values for the current logging context. A context represents a Node runtime in this case. 
     * IMPORTANT: This may impact other function runs as well. 
     * @param newConfig The updated configuration for the current logging context.
     */
    setConfig(newConfig: LoggerConfig): void;

    /**
     * Log a TRACE message. 
     * @param msg The log message.
     * @param ...args Any placeholder values.
     */
    trace(msg: string, ...args: any[]): void;

    /**
     * Log a DEBUG message. 
     * @param msg The log message.
     * @param ...args Any placeholder values.
     */
    debug(msg: string, ...args: any[]): void;

    /**
     * Log an INFO message. 
     * @param msg The log message.
     * @param ...args Any placeholder values.
     */
    info(msg: string, ...args: any[]): void;

    /**
     * Log a WARN message. 
     * @param msg The log message.
     * @param ...args Any placeholder values.
     */
    warn(msg: string, ...args: any[]): void;

    /**
     * Log an ERROR message. 
     * @param msg The log message.
     * @param ...args Any placeholder values.
     */
    error(msg: string, ...args: any[]): void;

    /**
     * Log a FATAL message. 
     * @param msg The log message.
     * @param ...args Any placeholder values.
     */
    fatal(msg: string, ...args: any[]): void;
}

/**
 * Represents a Log Timer instance of RFLIB, which starts counting the time at its instantiation.
 */
export interface LogTimer {

    /**
     * Stops the Log Timer instance and logs a message based on the threshold value. 
     */
    done(): void;
}

/**
 * Represents a factory method to create a logger instance. 
 * @param context Represents the Salesforce Function execution context.
 * @param computeLogger Represents the Salesforce Function Logger instance.
 * @param loggerName The name of the current logger instance.
 * @param shouldClearLogs Indicates if the current log stack should be cleared.
 */
export function createLogger(context: Context, computeLogger: Logger, loggerName: string, shouldClearLogs: boolean): RflibLogger;

/**
 * Initiates and starts a Log Timer instance. 
 * @param logger Represents the logger to which any statements should be printed to.
 * @param threshold The time in milliseconds after which a custom message should be logged.
 * @param timerName The name of the timer. 
 * @param logLevelStr (Optional) The Log Level that should be used for a message when the threshold is exceeded. Default is "WARN".
 */
export function startLogTimer(logger: RflibLogger, threshold: number, timerName: string, logLevelStr?: string): LogTimer;