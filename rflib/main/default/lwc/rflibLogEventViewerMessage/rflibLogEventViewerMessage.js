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
import { LightningElement, api } from 'lwc';

export default class RflibLogEventViewerMessage extends LightningElement {
    @api
    message;

    @api
    fieldVisibility;

    isExpanded = false;

    toggleJsonExpansion() {
        this.isExpanded = !this.isExpanded;
    }

    get expandIcon() {
        return this.isExpanded ? 'utility:collapse_all' : 'utility:expand_all';
    }

    get expandLabel() {
        return this.isExpanded ? 'Expand JSON' : 'Collapse JSON';
    }

    get wrapperClass() {
        let wrapperClass = 'wrapper ';
        if (!this.message) {
            return wrapperClass + 'light';
        }
        wrapperClass += this.message.lineId % 2 == 0 ? 'light' : 'dark';
        return wrapperClass;
    }

    get processedMessage() {
        if (!this.message?.content) {
            return '';
        }
        console.log(JSON.stringify(this.message));
        console.log(this.message.id);
        if (!this.message.content.includes('|')) {
            return this.message.content;
        }
        const parts = this.message.content.split('|');
        let processedTextArray = [];
        if (this.fieldVisibility.showDate) {
            processedTextArray.push(parts[0]);
        }
        if (this.fieldVisibility.showLogLevel && parts[1]) {
            processedTextArray.push(parts[1]);
        }
        if (this.fieldVisibility.showCreatedById && parts[2] && parts[2].startsWith('005')) {
            processedTextArray.push(parts[2]);
            if (this.fieldVisibility.showRequestId && parts[3] && parts.length >= 5) {
                processedTextArray.push(parts[3]);
                if (this.fieldVisibility.showContext && parts[4]) {
                    processedTextArray.push(parts[4]);
                }
                if (parts[4]) {
                    processedTextArray.push(parts.slice(5).join('|'));
                }
                return processedTextArray.join('|');
            } else if (parts[3]) {
                if (this.fieldVisibility.showContext && parts[3]) {
                    processedTextArray.push(parts[3]);
                }
                if (parts[3]) {
                    processedTextArray.push(parts.slice(4).join('|'));
                }
                return processedTextArray.join('|');
            }
        } else if (parts[2] && parts[2].startsWith('005')) {
            if (this.fieldVisibility.showRequestId && parts[3] && parts.length >= 5) {
                processedTextArray.push(parts[3]);
                if (this.fieldVisibility.showContext && parts[4]) {
                    processedTextArray.push(parts[4]);
                }
                processedTextArray.push(parts.slice(5).join('|'));
                return processedTextArray.join('|');
            }
            if (parts[4]) {
                if (this.fieldVisibility.showContext && parts[4]) {
                    processedTextArray.push(parts[4]);
                }
                processedTextArray.push(parts.slice(5).join('|'));

                return processedTextArray.join('|');
            }
        } else if (parts[2]) {
            if (this.fieldVisibility.showContext) {
                processedTextArray.push(parts[2]);
            }
            processedTextArray.push(parts.slice(3).join('|'));
        }
        return processedTextArray.join('|');
    }
}
