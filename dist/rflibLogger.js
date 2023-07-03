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

const state = {
    config: {
        stackSize: 100,
        computeLogLevel: LogLevel.DEBUG,
        serverLogLevel: LogLevel.WARN
    },

    messages: []
};

const format = (strToFormat, ...args) => {
    return strToFormat.replace(/{(\d+)}/g, function (match, number) {
        return typeof args[number] != 'undefined' ? args[number] : 'undefined';
    });
};

const addMessage = (message) => {
    if (state.messages.length >= state.config.stackSize) {
        state.messages.shift();
    }

    const fullMessage = new Date().toISOString() + '|' + message;
    state.messages.push(fullMessage);
};

const log = (level, component, message, context, computeLogger) => {
    const msgToLog = level.label + '|' + context.id + '|' + component + '|' + message;
    if (level.index >= state.config.computeLogLevel.index) {
        const computeLogLevel = level.label === 'FATAL' ? 'error' : level.label.toLowerCase();
        computeLogger[computeLogLevel](msgToLog);
    }

    addMessage(msgToLog);

    //eslint-disable-next-line no-use-before-define
    initializationPromise.then(() => {
        if (level.index >= state.config.serverLogLevel.index) {
            const platformInfo = Object.assign({}, process.resourceUsage(), process.memoryUsage());

            context.org.dataApi
                .create({
                    type: 'rflib_Log_Event__e',
                    fields: {
                        Log_Level__c: level.label,
                        Context__c: component.slice(-40),
                        Log_Messages__c: state.messages.join('\n'),
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

const toUpperCase = (text) => {
    if (text) {
        return text.toUpperCase();
    }
    return text;
};

let initializationPromise = null;

const createLogger = (context, computeLogger, loggerName, shouldClearLogs) => {
    const loggerSettingsQuery = `SELECT Archive_Log_Level__c, Functions_Log_Size__c, Functions_Compute_Log_Level__c, Functions_Server_Log_Level__c FROM rflib_Logger_Settings__c WHERE SetupOwnerId = '${context.org.id}'`;

    initializationPromise =
        context.org && context.org.id
            ? context.org.dataApi
                  .query(loggerSettingsQuery)
                  .then((result) => {
                      log(
                          LogLevel.DEBUG,
                          'rflibLogger',
                          'Retrieved settings for user: result=' +
                              JSON.stringify(result) +
                              ', current state.config=' +
                              JSON.stringify(state.config),
                          context,
                          computeLogger
                      );

                      state.config.stackSize = result.Functions_Log_Size__c || state.config.stackSize;
                      state.config.computeLogLevel =
                          LogLevel[toUpperCase(result.Functions_Compute_Log_Level__c)] || state.config.computeLogLevel;
                      state.config.serverLogLevel =
                          LogLevel[toUpperCase(result.Functions_Server_Log_Level__c)] || state.config.serverLogLevel;
                      state.config.archiveLogLevel =
                          LogLevel[toUpperCase(result.Archive_Log_Level__c)] || state.config.archiveLogLevel;

                      if (state.config.serverLogLevel.index <= LogLevel.DEBUG.index) {
                          state.config.serverLogLevel = LogLevel.INFO;
                      }
                  })
                  .catch((error) => {
                      computeLogger.error('>>> Failed to retrieve settings from server: ' + JSON.stringify(error));
                  })
            : new Promise(() => {
                  computeLogger.warn('>>> No org ID found: ' + JSON.stringify(context));
                  return {};
              });

    if (shouldClearLogs) {
        state.messages = [];
        log(LogLevel.DEBUG, 'rflibLogger', 'Cleared log messages', context, computeLogger);
    }

    const setConfig = (newConfig) => {
        log(
            LogLevel.DEBUG,
            loggerName,
            format('Setting new logger configuration for {0}, {1}', loggerName, JSON.stringify(newConfig)),
            context,
            computeLogger
        );

        state.config.stackSize = newConfig.stackSize || state.config.stackSize;
        state.config.computeLogLevel = LogLevel[toUpperCase(newConfig.computeLogLevel)] || state.config.computeLogLevel;
        state.config.serverLogLevel = LogLevel[toUpperCase(newConfig.serverLogLevel)] || state.config.serverLogLevel;

        if (state.config.serverLogLevel.index <= LogLevel.DEBUG.index) {
            state.config.serverLogLevel = LogLevel.INFO;
        }
    };

    const trace = (...args) => {
        log(LogLevel.TRACE, loggerName, format(...args), context, computeLogger);
    };

    const debug = (...args) => {
        log(LogLevel.DEBUG, loggerName, format(...args), context, computeLogger);
    };

    const info = (...args) => {
        log(LogLevel.INFO, loggerName, format(...args), context, computeLogger);
    };

    const warn = (...args) => {
        log(LogLevel.WARN, loggerName, format(...args), context, computeLogger);
    };

    const error = (...args) => {
        log(LogLevel.ERROR, loggerName, format(...args), context, computeLogger);
    };

    const fatal = (...args) => {
        log(LogLevel.FATAL, loggerName, format(...args), context, computeLogger);
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
                    [timerName, duration, threshold]
                ]);
            } else {
                logger.warn('{0} took a total of {1}ms (threshold={2}ms). NOTE: Invalid log Level provided', [
                    timerName,
                    duration,
                    threshold
                ]);
            }
        } else {
            logger.trace('{0} took a total of {1}ms (threshold={2}ms)', [timerName, duration, threshold]);
        }
    };

    return {
        done: done
    };
};

const createApplicationEventLogger = (context, computeLogger) => {
    const logger = createLogger(context, computeLogger, 'rflib-application-event-logger');

    return appEventLogger.createApplicationEventLogger(context, logger);
};

module.exports = {
    createLogger,
    startLogTimer,
    createApplicationEventLogger
};
