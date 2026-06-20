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
/**
 * Host-supplied Salesforce data adapter. The host (e.g. an LWR on Node.js app) wraps an
 * authenticated connection — typically a jsforce Connection backed by a JWT Bearer integration
 * user — into this minimal shape. The logger reads its settings via `query` and publishes log /
 * application events via `create`; it does not perform authentication itself.
 */
export interface DataApi {
    /**
     * Runs a SOQL query and resolves the first matching record (or undefined).
     * @param soql The SOQL query string.
     */
    query(soql: string): Promise<any>;

    /**
     * Publishes a platform event record.
     * @param record The record to create: { type, fields }.
     */
    create(record: { type: string; fields: Record<string, any> }): Promise<any>;
}

/**
 * Per-request/per-user logging context. The host creates one logger per context and never shares
 * an instance across users.
 * @property id The request/transaction id, recorded as Request_Id__c.
 * @property org The org whose rflib_Logger_Settings__c hierarchy applies (SetupOwnerId = org.id).
 * @property user The acting user, recorded as Created_By_ID__c on application events.
 */
export interface LoggerContext {
    readonly id: string;
    readonly org?: { readonly id: string };
    readonly user?: { readonly id?: string; readonly onBehalfOfUserId?: string };
}

/**
 * A console-like sink for the compute (stdout) log stream. Defaults to the global `console`.
 */
export interface ComputeLogger {
    trace?(message: string): void;
    debug(message: string): void;
    info(message: string): void;
    warn(message: string): void;
    error(message: string): void;
}

/**
 * Options for creating a logger instance.
 * @property computeLogger (Optional) Console-like sink for the compute log stream. Defaults to `console`.
 * @property shouldClearLogs (Optional) Clears the instance log stack on creation.
 * @property platformInfoProvider (Optional) Returns the object stored in Platform_Info__c when a log
 *           event is published. Defaults to a Node/LWR runtime telemetry payload (process memory, cpu,
 *           uptime, version) nested under a `node` key.
 */
export interface LoggerOptions {
    readonly computeLogger?: ComputeLogger;
    readonly shouldClearLogs?: boolean;
    readonly platformInfoProvider?: () => Record<string, any>;
}

/**
 * Represents the configuration of the RFLIB Logger instance. Use this object
 * when overriding the configuration retrieved from the server instance.
 * @property stackSize (Optional) The number of log messages to be stored in the log stack.
 * @property computeLogLevel (Optional) The minimum log level for messages to be forwarded to the compute (stdout) logger.
 * @property serverLogLevel (Optional) The minimum log level for messages to be submitted as a platform event. The lowest possible level is INFO.
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
     * Set new configuration values for this logger instance only. Because each instance owns its
     * own state, this does not affect loggers created for other requests or users.
     * @param newConfig The updated configuration for this logger instance.
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
 * Represents a Log Timer instance of RFLIB, which starts counting the time of its instantiation.
 */
export interface RflibLogTimer {
    /**
     * Stops the Log Timer instance and logs a message based on the threshold value.
     */
    done(): void;
}

/**
 * Represents a Application Event Logger instance of RFLIB.
 */
export interface RflibApplicationEventLogger {
    /**
     * Log an Application Event.
     * @param eventName The name of the application event.
     * @param relatedRecordId A Salesforce record ID the event is related to.
     * @param additionalDetails Any additional details related to the event; serialized with JSON.stringify, so a string or any serializable object may be passed.
     */
    logApplicationEvent(eventName: string, relatedRecordId?: string, additionalDetails?: unknown): void;
}

/**
 * Factory method to create a logger instance bound to a single request/user context. Each call
 * returns an isolated instance with its own log stack; never share an instance across users.
 * @param dataApi Host-supplied Salesforce data adapter (query + create).
 * @param context Per-request/per-user logging context.
 * @param loggerName The name of the current logger instance.
 * @param options (Optional) computeLogger, shouldClearLogs, and platformInfoProvider overrides.
 */
export function createLogger(
    dataApi: DataApi,
    context: LoggerContext,
    loggerName: string,
    options?: LoggerOptions
): RflibLogger;

/**
 * Initiates and starts a Log Timer instance.
 * @param logger Represents the logger to which any statements should be printed to.
 * @param threshold The time in milliseconds after which a custom message should be logged.
 * @param timerName The name of the timer.
 * @param logLevelStr (Optional) The Log Level that should be used for a message when the threshold is exceeded. Default is "WARN".
 */
export function startLogTimer(
    logger: RflibLogger,
    threshold: number,
    timerName: string,
    logLevelStr?: string
): RflibLogTimer;

/**
 * Factory method to create an application event logger instance bound to a single request/user context.
 * @param dataApi Host-supplied Salesforce data adapter (query + create).
 * @param context Per-request/per-user logging context.
 * @param options (Optional) computeLogger, shouldClearLogs, and platformInfoProvider overrides.
 */
export function createApplicationEventLogger(
    dataApi: DataApi,
    context: LoggerContext,
    options?: LoggerOptions
): RflibApplicationEventLogger;
