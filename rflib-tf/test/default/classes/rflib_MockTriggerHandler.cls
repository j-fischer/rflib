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
 @SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_MockTriggerHandler implements rflib_TriggerHandler {
    
    private static final rflib_Logger LOGGER = new rflib_DefaultLoggerFactory().createLogger('rflib_MockTriggerHandler');

    // These fields have to be static because the class gets instantiated by the TriggerManager, not injected.
    public static List<rflib_TriggerManager.Args> CAPTURED_RUN_TRIGGER_ARGS = new List<rflib_TriggerManager.Args>();
    public static List<rflib_TriggerManager.Args> CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS = new List<rflib_TriggerManager.Args>();

    public static Exception EXCEPTION_ON_RUN = null;
    public static Exception EXCEPTION_ON_CONSECUTIVE_RUN = null;

    public static Callable ACTION_WHEN_CALLED = null;

    public void run(rflib_TriggerManager.Args args) {
        LOGGER.info('run() invoked');

        CAPTURED_RUN_TRIGGER_ARGS.add(args);

        LOGGER.info('will run action={0}, should throw exception={1} ', new object[] { (ACTION_WHEN_CALLED != null), (EXCEPTION_ON_RUN != null) });
        if (ACTION_WHEN_CALLED != null) {
            ACTION_WHEN_CALLED.call('run', new Map<String, Object> { 'triggerArgs' => args });
        }

        if (EXCEPTION_ON_RUN != null) {
            throw EXCEPTION_ON_RUN;
        }
    }

    public void onConsecutiveRun(rflib_TriggerManager.Args args, Integer numInvocation) {
        CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS.add(args);
        
        LOGGER.info('onConsecutiveRun invoked, will run action={0}, should throw exception={1} ', new object[] { (ACTION_WHEN_CALLED != null), (EXCEPTION_ON_RUN != null) });
        if (ACTION_WHEN_CALLED != null) {
            ACTION_WHEN_CALLED.call('onConsecutiveRun', new Map<String, Object> { 'triggerArgs' => args, 'numInvocation' => numInvocation });
        }

        if (EXCEPTION_ON_CONSECUTIVE_RUN != null) {
            throw EXCEPTION_ON_CONSECUTIVE_RUN;
        } 
    }
}
