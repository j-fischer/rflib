import { Download } from '@playwright/test';
import { promises as fs } from 'fs';
import os from 'os';
import path from 'path';

export interface ParsedCsv {
    header: string[];
    rows: string[][];
}

/**
 * Reads a download's bytes.
 *
 * The file is saved to a path of our own first. Reading the runner's own artifact copy through
 * createReadStream() came back empty for blob downloads, including for a one line probe file.
 */
export async function readDownload(download: Download): Promise<string> {
    const failure = await download.failure();
    if (failure) {
        throw new Error(`Download ${download.suggestedFilename()} failed: ${failure}`);
    }

    const target = path.join(os.tmpdir(), `rflib-e2e-${Date.now()}-${download.suggestedFilename()}`);
    await download.saveAs(target);

    try {
        return await fs.readFile(target, 'utf8');
    } finally {
        await fs.rm(target, { force: true });
    }
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
