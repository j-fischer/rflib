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
import logMessageToServer from '@salesforce/apex/rflib_LoggerController.log';

const LogLevel = Object.freeze({
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
        consoleLogLevel: LogLevel.INFO,
        serverLogLevel: LogLevel.FATAL
    },

    messages: []
};

const format = (strToFormat, ...args) => {
    return strToFormat.replace(/{(\d+)}/g, function(match, number) {
        return typeof args[number] != 'undefined' ? args[number] : match;
    });
};

const addMessage = message => {
    if (state.messages.length >= state.config.stackSize) {
        state.messages.shift();
    }

    let fullMessage = new Date().toISOString() + '|' + message;
    state.messages.push(fullMessage);
};

const log = (level, component, message) => {
    let msgToLog = level.label + '|' + component + '|' + message;
    if (level.index >= state.config.consoleLogLevel.index) {
        window.console.log(msgToLog);
    }

    addMessage(msgToLog);

    if (level.index >= state.config.serverLogLevel.index) {
        logMessageToServer({
            level: level.label,
            context: component,
            message: message
        }).catch(error => {
            window.console.log('Failed to log message to server for: ' + JSON.stringify(error));
        });
    }
};

const createLogger = loggerName => {
    const setConfig = newConfig => {
        state.config.stackSize = newConfig.stackSize || state.config.stackSize;
        state.config.consoleLogLevel = newConfig.consoleLogLevel || state.config.consoleLogLevel;
        state.config.serverLogLevel = newConfig.serverLogLevel || state.config.serverLogLevel;
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
        debug: debug,
        info: info,
        warn: warn,
        error: error,
        fatal: fatal
    };
};

export { createLogger };
