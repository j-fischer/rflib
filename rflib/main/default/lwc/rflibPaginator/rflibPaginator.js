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

export const PAGE_SIZES = [10, 25, 50, 100];

/**
 * Returns the given value as a page size if it is one of the supported PAGE_SIZES, otherwise the fallback.
 * Values configured in the Lightning App Builder arrive as strings, so they are parsed first.
 */
export function getValidPageSize(value, fallback) {
    const pageSize = parseInt(value, 10);
    return PAGE_SIZES.includes(pageSize) ? pageSize : fallback;
}

export default class Paginator extends LightningElement {
    @api totalRecords;
    @api currentPage;
    @api pageSize;

    // Deprecated: the page selection is always displayed. Kept so that existing markup remains valid.
    @api shouldDisplayPageSelection = false;

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize) || 1;
    }

    get pageSizeOptions() {
        return PAGE_SIZES.map((size) => ({ label: String(size), value: String(size) }));
    }

    get selectedPageSize() {
        return String(this.pageSize);
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
        if (evt.keyCode === 13 || evt.key === 'Enter') {
            const enteredPage = parseInt(evt.target.value, 10);
            const selectedPage = isNaN(enteredPage)
                ? this.currentPage
                : Math.min(Math.max(enteredPage, 1), this.totalPages);

            // The input is not re-rendered if the current page does not change, i.e. when the
            // entered value was clipped to the page that is already displayed.
            evt.target.value = selectedPage;

            if (!import.meta.env.SSR) {
                this.dispatchEvent(new CustomEvent('gotopage', { detail: selectedPage }));
            }
        }
    }

    handlePageSizeChange(evt) {
        const newPageSize = getValidPageSize(evt.detail.value, this.pageSize);

        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('pagesizechange', { detail: newPageSize }));
        }
    }
}
