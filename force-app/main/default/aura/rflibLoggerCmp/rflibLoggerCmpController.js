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
({
    doInit: function(component) {
        var name = component.get('v.name');
        var appendComponentId = component.get('v.appendComponentId');

        if (appendComponentId) {
            name = name + component.getGlobalId();
        }

        var loggerFactory = component.find('loggerFactory');
        var logger = loggerFactory.createLogger(name);

        component.set('v.logger', logger);
    },

    setConfig: function(component, event) {
        var params = event.getParam('arguments');
        if (params) {
            var logger = component.get('v.logger');
            logger.setConfig(params.newConfig);
        }
    },

    debug: function(component, event, helper) {
        var logger = component.get('v.logger');
        logger.debug.apply(logger, helper.getArgs(event, helper));
    },

    info: function(component, event, helper) {
        var logger = component.get('v.logger');
        logger.info.apply(logger, helper.getArgs(event, helper));
    },

    warn: function(component, event, helper) {
        var logger = component.get('v.logger');
        logger.warn.apply(logger, helper.getArgs(event, helper));
    },

    error: function(component, event, helper) {
        var logger = component.get('v.logger');
        logger.error.apply(logger, helper.getArgs(event, helper));
    },

    fatal: function(component, event, helper) {
        var logger = component.get('v.logger');
        logger.fatal.apply(logger, helper.getArgs(event, helper));
    }
});
