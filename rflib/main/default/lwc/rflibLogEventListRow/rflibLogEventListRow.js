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
import { api, LightningElement } from 'lwc';

export default class RflibLogEventListRow extends LightningElement {
    @api evt;

    get createdBy() {
        return this.evt.CreatedById || this.evt.CreatedById__c;
    }

    get createdDate() {
        return this.evt.CreatedDate || this.evt.CreatedDate__c;
    }

    get logLevel() {
        return this.evt.Log_Level__c;
    }

    get rowClass() {
        const baseClass = 'log-row';
        const levelClass = this.getLevelClass();
        return `${baseClass} ${levelClass}`;
    }

    get logLevelClass() {
        const baseClass = 'log-level';
        const levelClass = this.getLevelClass();
        return `${baseClass} ${levelClass}`;
    }

    getLevelClass() {
        const level = this.logLevel?.toLowerCase();
        switch (level) {
            case 'error':
                return 'level-error';
            case 'warn':
            case 'warning':
                return 'level-warn';
            case 'info':
                return 'level-info';
            case 'debug':
                return 'level-debug';
            case 'trace':
                return 'level-trace';
            default:
                return 'level-default';
        }
    }
}
