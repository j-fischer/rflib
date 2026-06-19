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

const os = require('os');
const appEventLogger = require('./rflibApplicationEventLogger');

const LogLevel = Object.freeze({
    TRACE: { index: 0, label: 'TRACE' },
    DEBUG: { index: 1, label: 'DEBUG' },
    INFO: { index: 2, label: 'INFO' },
    WARN: { index: 3, label: 'WARN' },
    ERROR: { index: 4, label: 'ERROR' },
    FATAL: { index: 5, label: 'FATAL' },
    NONE: { index: 100, label: 'NONE' }
});

const convertToString = (arg) => {
    if (arg === undefined) return 'undefined';
    if (arg === null) return 'null';

    switch (typeof arg) {
        case 'object':
            try {
                return JSON.stringify(arg);
            } catch (error) {
                return '[Circular Object]';
            }
        case 'function':
            return 'function';
        case 'symbol':
            return arg.toString();
        case 'bigint':
            return arg.toString();
        default:
            return String(arg);
    }
};

const format = (strToFormat, ...args) => {
    return strToFormat.replace(/{(\d+)}/g, function (match, number) {
        return typeof args[number] !== 'undefined' ? convertToString(args[number]) : 'undefined';
    });
};

const toUpperCase = (text) => {
    if (text) {
        return text.toUpperCase();
    }
    return text;
};

// Default Platform_Info__c payload for a Node/LWR runtime. The data is nested under a single
// "node" key so the Apex rflib_PlatformInfoParser flattens it generically to rflib.platform.node.*,
// the same way it flattens the browser performance payload. A host can pass options.platformInfoProvider
// to replace or extend this (e.g. to add LWR request route, SSR flag, or request duration).
const collectPlatformInfo = () => ({
    node: {
        version: process.version,
        pid: process.pid,
        hostname: os.hostname(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        cpu: process.cpuUsage()
    }
});

/**
 * Creates an RFLIB logger bound to a single request/user context. Each invocation returns an
 * isolated instance with its own in-memory log stack and configuration; instances never share
 * state, so a long-running, multi-user host (such as LWR on Node.js) must create one logger per
 * user/request and must not reuse a single instance across users.
 *
 * @param {{query: Function, create: Function}} dataApi Host-supplied Salesforce data adapter. `query`
 *        runs SOQL and resolves the first record; `create` publishes a platform event
 *        ({ type, fields }). The host typically adapts a jsforce Connection to this shape.
 * @param {object} context Per-request context: { id, org: { id }, user: { id, onBehalfOfUserId } }.
 * @param {string} loggerName The name of the current logger instance.
 * @param {object} [options] { computeLogger = console, shouldClearLogs = false, platformInfoProvider }.
 */
const createLogger = (dataApi, context, loggerName, options) => {
    const opts = options || {};
    const computeLogger = opts.computeLogger || console;
    const platformInfoProvider =
        typeof opts.platformInfoProvider === 'function' ? opts.platformInfoProvider : collectPlatformInfo;

    // Per-instance state. A fresh stack and config per context is what keeps one user's log
    // messages from leaking into another user's published Log Event on a shared server.
    const config = {
        stackSize: 100,
        computeLogLevel: LogLevel.DEBUG,
        serverLogLevel: LogLevel.WARN,
        archiveLogLevel: LogLevel.NONE
    };
    let messages = [];

    const addMessage = (message) => {
        if (messages.length >= config.stackSize) {
            messages.shift();
        }

        const fullMessage = new Date().toISOString() + '|' + message;
        messages.push(fullMessage);
    };

    let initializationPromise = null;

    const log = (level, component, message) => {
        const msgToLog = level.label + '|' + context.id + '|' + component + '|' + message;
        if (level.index >= config.computeLogLevel.index) {
            const computeLogLevel = level.label === 'FATAL' ? 'error' : level.label.toLowerCase();
            computeLogger[computeLogLevel](msgToLog);
        }

        addMessage(msgToLog);

        initializationPromise.then(() => {
            if (level.index >= config.serverLogLevel.index) {
                let platformInfo;
                try {
                    platformInfo = platformInfoProvider();
                } catch (error) {
                    platformInfo = {};
                }

                dataApi
                    .create({
                        type: 'rflib_Log_Event__e',
                        fields: {
                            Log_Level__c: level.label,
                            Context__c: component.slice(-40),
                            Log_Messages__c: messages.join('\n'),
                            Request_Id__c: context.id.slice(-40),
                            Platform_Info__c: JSON.stringify(platformInfo)
                        }
                    })
                    .catch((error) => {
                        computeLogger.error('>>> Failed to log message to server for: ' + JSON.stringify(error));
                    });
            }
        });
    };

    const applyServerLogLevelFloor = () => {
        if (config.serverLogLevel.index <= LogLevel.DEBUG.index) {
            config.serverLogLevel = LogLevel.INFO;
        }
    };

    const loggerSettingsQuery = `SELECT Client_Console_Log_Level__c, Client_Server_Log_Level__c, Client_Log_Size__c, Archive_Log_Level__c FROM rflib_Logger_Settings__c WHERE SetupOwnerId = '${context.org && context.org.id}'`;

    initializationPromise =
        context.org && context.org.id
            ? dataApi
                  .query(loggerSettingsQuery)
                  .then((result) => {
                      log(
                          LogLevel.DEBUG,
                          'rflibLogger',
                          'Retrieved settings for user: result=' +
                              JSON.stringify(result) +
                              ', current config=' +
                              JSON.stringify(config)
                      );

                      config.stackSize = result.Client_Log_Size__c || config.stackSize;
                      config.computeLogLevel =
                          LogLevel[toUpperCase(result.Client_Console_Log_Level__c)] || config.computeLogLevel;
                      config.serverLogLevel =
                          LogLevel[toUpperCase(result.Client_Server_Log_Level__c)] || config.serverLogLevel;
                      config.archiveLogLevel =
                          LogLevel[toUpperCase(result.Archive_Log_Level__c)] || config.archiveLogLevel;

                      applyServerLogLevelFloor();
                  })
                  .catch((error) => {
                      computeLogger.error('>>> Failed to retrieve settings from server: ' + JSON.stringify(error));
                  })
            : Promise.resolve().then(() => {
                  computeLogger.warn('>>> No org ID found: ' + JSON.stringify(context));
              });

    if (opts.shouldClearLogs) {
        messages = [];
        log(LogLevel.DEBUG, 'rflibLogger', 'Cleared log messages');
    }

    const setConfig = (newConfig) => {
        log(
            LogLevel.DEBUG,
            loggerName,
            format('Setting new logger configuration for {0}, {1}', loggerName, JSON.stringify(newConfig))
        );

        config.stackSize = newConfig.stackSize || config.stackSize;
        config.computeLogLevel = LogLevel[toUpperCase(newConfig.computeLogLevel)] || config.computeLogLevel;
        config.serverLogLevel = LogLevel[toUpperCase(newConfig.serverLogLevel)] || config.serverLogLevel;

        applyServerLogLevelFloor();
    };

    const trace = (...args) => {
        log(LogLevel.TRACE, loggerName, format(...args));
    };

    const debug = (...args) => {
        log(LogLevel.DEBUG, loggerName, format(...args));
    };

    const info = (...args) => {
        log(LogLevel.INFO, loggerName, format(...args));
    };

    const warn = (...args) => {
        log(LogLevel.WARN, loggerName, format(...args));
    };

    const error = (...args) => {
        log(LogLevel.ERROR, loggerName, format(...args));
    };

    const fatal = (...args) => {
        log(LogLevel.FATAL, loggerName, format(...args));
    };

    return {
        setConfig: setConfig,
        trace: trace,
        debug: debug,
        info: info,
        warn: warn,
        error: error,
        fatal: fatal
    };
};

const startLogTimer = (logger, threshold, timerName, logLevelStr) => {
    const logMethodName = (logLevelStr || 'warn').toLowerCase();

    const startTime = new Date().getTime();

    const done = () => {
        const endTime = new Date().getTime();
        const duration = endTime - startTime;

        if (duration > threshold) {
            if (typeof logger[logMethodName] === 'function') {
                logger[logMethodName].apply(logger, [
                    '{0} took a total of {1}ms (threshold={2}ms).',
                    timerName,
                    duration,
                    threshold
                ]);
            } else {
                logger.warn(
                    '{0} took a total of {1}ms (threshold={2}ms). NOTE: Invalid log Level provided',
                    timerName,
                    duration,
                    threshold
                );
            }
        } else {
            logger.trace('{0} took a total of {1}ms (threshold={2}ms).', timerName, duration, threshold);
        }
    };

    return {
        done: done
    };
};

const createApplicationEventLogger = (dataApi, context, options) => {
    const logger = createLogger(dataApi, context, 'rflib-application-event-logger', options);

    return appEventLogger.createApplicationEventLogger(dataApi, context, logger);
};

module.exports = {
    createLogger,
    startLogTimer,
    createApplicationEventLogger
};
