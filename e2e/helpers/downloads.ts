import { Download } from '@playwright/test';
import { promises as fs } from 'fs';

const READ_ATTEMPTS = 20;
const READ_RETRY_MS = 250;

export interface ParsedCsv {
    header: string[];
    rows: string[][];
}

/**
 * Reads a download's bytes.
 *
 * On Windows the browser process keeps its handle on the artifact open for a moment after the
 * download completes, so the first read fails with EPERM even though the file is already complete
 * (stat reports the full size). The read is retried until the handle is released; without the retry
 * saveAs() and createReadStream() fail too - the latter silently, by returning nothing.
 */
export async function readDownload(download: Download): Promise<string> {
    const failure = await download.failure();
    if (failure) {
        throw new Error(`Download ${download.suggestedFilename()} failed: ${failure}`);
    }

    const artifact = await download.path();

    let lastError: unknown;
    for (let attempt = 0; attempt < READ_ATTEMPTS; attempt++) {
        try {
            return await fs.readFile(artifact, 'utf8');
        } catch (error) {
            lastError = error;
            await new Promise((resolve) => setTimeout(resolve, READ_RETRY_MS));
        }
    }

    throw new Error(
        `Could not read the download ${download.suggestedFilename()} at ${artifact} after ` +
            `${READ_ATTEMPTS} attempts: ${(lastError as Error)?.message}`
    );
}

/**
 * Splits an RFLIB CSV export into cells.
 *
 * The exports quote every field and escape an embedded quote by doubling it, and no value contains a
 * newline, so lines can be split on CRLF before the cells are split on the quote/comma/quote seam.
 */
export function parseCsv(text: string): ParsedCsv {
    const lines = text.split('\r\n').filter((line) => line.length > 0);
    const cells = lines.map((line) =>
        line
            .replace(/^"/, '')
            .replace(/"$/, '')
            .split('","')
            .map((value) => value.replace(/""/g, '"'))
    );

    return { header: cells[0] ?? [], rows: cells.slice(1) };
}

export async function readCsvDownload(download: Download): Promise<ParsedCsv> {
    return parseCsv(await readDownload(download));
}
