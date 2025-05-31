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
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('rflibLogEventViewerMessage');

export default class RflibLogEventViewerMessage extends LightningElement {
    @api
    message;

    @api
    fieldVisibility;

    isExpanded = false;

    toggleJsonExpansion() {
        logger.debug('Toggling JSON expansion, current state={0}', this.isExpanded);
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
            logger.debug('No message content found');
            return '';
        }

        if (!this.message.content.includes('|')) {
            logger.debug('Message content does not contain structured format');
            return this.message.content;
        }

        logger.debug('Processing structured message content');
        return this.parseStructuredMessage(this.message.content);
    }

    parseStructuredMessage(content) {
        const parts = content.split('|');
        logger.debug('Split message into {0} parts', parts.length);

        if (parts.length < 6) {
            logger.debug('Not enough parts for structured message, returning original content');
            return content;
        }

        const fields = this.extractFields(parts);
        const visibleFields = this.buildVisibleFields(fields);

        logger.debug('Built {0} visible fields from message', visibleFields.length);
        return visibleFields.join(' | ');
    }

    extractFields(parts) {
        let messageStartIndex = 5;

        const fields = {
            date: parts[0] || '',
            logLevel: parts[1] || '',
            userId: parts[2] || '',
            requestId: parts[3] || '',
            context: parts[4] || '',
            message: parts.slice(messageStartIndex).join('|')
        };

        logger.debug(
            'Extracted fields: date={0}, logLevel={1}, userId={2}, requestId={3}, context={4}',
            fields.date,
            fields.logLevel,
            fields.userId,
            fields.requestId,
            fields.context
        );

        return fields;
    }

    buildVisibleFields(fields) {
        logger.debug(
            'Field visibility settings: showDate={0}, showLogLevel={1}, showCreatedBy={2}, showRequestId={3}, showContext={4}',
            this.fieldVisibility.showDate,
            this.fieldVisibility.showLogLevel,
            this.fieldVisibility.showCreatedBy,
            this.fieldVisibility.showRequestId,
            this.fieldVisibility.showContext
        );

        const visibleFields = [];
        if (this.fieldVisibility.showDate && fields.date) {
            visibleFields.push(fields.date);
        }

        if (this.fieldVisibility.showLogLevel && fields.logLevel) {
            visibleFields.push(fields.logLevel);
        }

        if (this.fieldVisibility.showCreatedBy && fields.userId) {
            visibleFields.push(fields.userId);
        }

        if (this.fieldVisibility.showRequestId && fields.requestId) {
            visibleFields.push(fields.requestId);
        }

        if (this.fieldVisibility.showContext && fields.context) {
            visibleFields.push(fields.context);
        }

        if (fields.message) {
            visibleFields.push(fields.message);
        }

        return visibleFields;
    }
}
