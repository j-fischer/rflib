/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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

/*
 * Two Lightning Web Security rules shape everything in this module, and both fail loudly enough to
 * abandon a download but quietly enough to look like nothing happened:
 *
 * 1. Assigning a `data:` URL to an anchor's href throws, so the content has to travel as a Blob
 *    behind an object URL. That also removes the browser's maximum URL length as a ceiling on the
 *    export size, which a percent-encoded data URL runs into at a few tens of thousands of rows.
 * 2. URL.createObjectURL() rejects most Blob MIME types with "Unsupported MIME type", including
 *    `text/csv` and anything carrying a `;charset=` parameter - `text/plain;charset=utf-8` is
 *    refused where bare `text/plain` is accepted. `application/octet-stream` is on the allowed list
 *    and is the conventional type for a file that is meant to be saved rather than displayed, so
 *    every download here uses it and lets the file name's extension say what the file is.
 */
const DOWNLOAD_MIME_TYPE = 'application/octet-stream';

/**
 * Hands a generated text file to the browser.
 *
 * @param {HTMLElement} container an `lwc:dom="manual"` element to host the anchor while it is clicked
 * @param {string} fileName the name offered to the browser
 * @param {string} content the file content
 */
export function downloadFile(container, fileName, content) {
    const objectUrl = URL.createObjectURL(new Blob([content], { type: DOWNLOAD_MIME_TYPE }));

    const element = document.createElement('a');
    element.setAttribute('href', objectUrl);
    element.setAttribute('download', sanitizeFileName(fileName));
    element.style.display = 'none';

    container.appendChild(element);

    try {
        element.click();
    } finally {
        container.removeChild(element);
        // Unlike a data URL, an object URL holds on to the blob until it is released.
        URL.revokeObjectURL(objectUrl);
    }
}

/**
 * Builds the timestamp suffix used by the RFLIB exports. `toISOString()` contains colons, which
 * Windows does not allow in a file name and browsers silently rewrite.
 */
export function fileNameTimestamp() {
    return new Date().toISOString().replace(/:/g, '-');
}

function sanitizeFileName(fileName) {
    return fileName.replace(/[:\\/?*"<>|]/g, '-');
}
