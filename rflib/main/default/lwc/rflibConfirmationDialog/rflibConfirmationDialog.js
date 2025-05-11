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
 * Created by marcoalmodova on 23/02/2020.
 * Big thanks to Marco Almodova (https://github.com/marcoalmodova) for providing this component and granting the right
 * to license it under RFLIB's BSD-3-Clause license.
 * Please check out https://github.com/marcoalmodova/confirm-dialog for the original version of the code.
 */
import { LightningElement, api } from 'lwc';

export default class ConfirmationDialog extends LightningElement {
    @api visible = false; //used to hide/show dialog
    @api title = ''; //modal title
    @api name; //reference name of the component
    @api message = ''; //modal message
    @api confirmLabel = ''; //confirm button label
    @api cancelLabel = ''; //cancel button label
    @api originalMessage; //any event/message/detail to be published back to the parent component

    //handles button clicks
    handleClick(event) {
        //creates object which will be published to the parent component
        let finalEvent = {
            originalMessage: this.originalMessage,
            status: event.target.name
        };

        //dispatch a 'click' event so the parent component can handle it
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('modalaction', { detail: finalEvent }));
        }
    }
}
