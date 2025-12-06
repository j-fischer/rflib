/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
public class rflib_BigObjectStatTriggerHandler {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BigObjectStatTriggerHandler');

    @TestVisible
    private static rflib_EventPublisher EVENT_PUBLISHER = new rflib_EventBusPublisher();

    public static void handleTrigger(System.TriggerOperation operation) {
        try {
            if (operation == System.TriggerOperation.AFTER_INSERT 
                    || operation == System.TriggerOperation.AFTER_UPDATE
                    || operation == System.TriggerOperation.AFTER_DELETE) {
                publishEvent();
            }
        } catch (Exception e) {
            LOGGER.error('Error publishing Big Object Stat event: {0}', new Object[] { e.getMessage() }, e);
        }
    }

    private static void publishEvent() {
        Database.SaveResult result = EVENT_PUBLISHER.publish(new rflib_Big_Object_Stat_Event__e());

        if (!result.isSuccess()) {
            for (Database.Error error : result.getErrors()) {
                LOGGER.error('Failed to publish Big Object Stat event: {0}', new Object[] { error.getMessage() });
            }
        }
    }
}
