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
 *
 * This component was inspired by:
 * https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
 */
import { LightningElement, api } from 'lwc';
export default class Paginator extends LightningElement {
    @api totalRecords;
    @api currentPage;
    @api pageSize;

    @api shouldDisplayPageSelection = false;

    lastpage = false;
    firstpage = false;

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get shouldDisableFirstButton() {
        if (this.currentPage === 1) {
            return true;
        }
        return false;
    }

    get shouldDisableLastButton() {
        if (this.totalRecords === 0 || this.totalPages === this.currentPage) {
            return true;
        }
        return false;
    }

    handlePrevious() {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('previous'));
        }
    }

    handleNext() {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('next'));
        }
    }

    handleFirst() {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('first'));
        }
    }

    handleLast() {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('last'));
        }
    }

    handlePageNumberChange(evt) {
        if (evt.keyCode === 13) {
            let selectedPage =
                evt.target.value > this.totalPages ? this.totalPages : evt.target.value < 1 ? 1 : evt.target.value;

            if (!import.meta.env.SSR) {
                this.dispatchEvent(new CustomEvent('gotopage', { detail: selectedPage }));
            }
        }
    }
}
