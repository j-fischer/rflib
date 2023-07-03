/*
 * Copyright (c) 2023 Johannes Fischer <fischer.jh@gmail.com>
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

const createApplicationEventLogger = (context, logger) => {
    const logApplicationEvent = (eventName, relatedRecordId, additionalDetails) => {
        logger.info(
            'Logging Application Event "{0}" for record "{1}" with details: {2}',
            eventName,
            relatedRecordId,
            additionalDetails
        );
        context.org.dataApi
            .create({
                type: 'rflib_Application_Event_Occurred_Event__e',
                fields: {
                    Event_Name__c: eventName,
                    Occurred_On__c: new Date().toISOString(),
                    Related_Record_ID__c: relatedRecordId || 'NO_RECORD_ID',
                    Additional_Details__c: JSON.stringify(additionalDetails),
                    Created_By_ID__c: context.org.user.onBehalfOfUserId || context.org.user.id
                }
            })
            .then(() => {
                logger.debug('Application Event successfully recorded');
            })
            .catch((error) => {
                logger.error(
                    'Failed to log application event to server for: {0}, error={1}',
                    eventName,
                    JSON.stringify(error)
                );
            });
    };

    return {
        logApplicationEvent: logApplicationEvent
    };
};

module.exports = {
    createApplicationEventLogger
};
