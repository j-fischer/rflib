import { execFileSync } from 'node:child_process';
import * as fs from 'node:fs';
import * as path from 'node:path';

const IS_WINDOWS = process.platform === 'win32';

export const AUTH_DIR = path.join(__dirname, '..', '.auth');
export const ORG_INFO_PATH = path.join(AUTH_DIR, 'org.json');
export const STORAGE_STATE_PATH = path.join(AUTH_DIR, 'storageState.json');
export const REPO_ROOT = path.join(__dirname, '..', '..');

export interface OrgInfo {
    username: string;
    instanceUrl: string;
    adminName: string;
}

// execFileSync with shell:true does not quote arguments, so quote anything with whitespace.
function quoteForShell(arg: string): string {
    return /\s/.test(arg) ? `"${arg}"` : arg;
}

export function sf(args: string[]): string {
    // The gulp test-e2e task sets RFLIB_E2E_TARGET_ORG to the entered org alias;
    // without it the sf CLI default org applies.
    const targetOrg = process.env.RFLIB_E2E_TARGET_ORG;
    if (targetOrg) {
        args = [...args, '--target-org', targetOrg];
    }
    // Node >=20 refuses to spawn .cmd shims without a shell (CVE-2024-27980 fix),
    // so on Windows run through the shell; args contain no user input.
    return execFileSync(IS_WINDOWS ? 'sf.cmd' : 'sf', IS_WINDOWS ? args.map(quoteForShell) : args, {
        encoding: 'utf8',
        shell: IS_WINDOWS,
        cwd: REPO_ROOT,
        maxBuffer: 64 * 1024 * 1024
    });
}

export function sfJson(args: string[]): any {
    // Local sf wrappers may print noise (code page changes, spinner output)
    // before the JSON, so strip ANSI codes and try each line starting with '{'.
    // eslint-disable-next-line no-control-regex
    const output = sf([...args, '--json']).replace(/\x1b\[[0-9;]*[A-Za-z]/g, '');
    const lines = output.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('{')) {
            const candidate = lines.slice(i).join('\n');
            const start = candidate.indexOf('{');
            const end = candidate.lastIndexOf('}');
            if (end > start) {
                try {
                    return JSON.parse(candidate.substring(start, end + 1));
                } catch {
                    // keep scanning; noise line happened to start with '{'
                }
            }
        }
    }
    throw new Error(`No parseable JSON in sf output: ${output.substring(0, 500)}`);
}

export function runApex(file: string): void {
    const result = sfJson(['apex', 'run', '--file', file]);
    if (result.status !== 0 || !result.result?.success) {
        throw new Error(`Apex script ${file} failed: ${JSON.stringify(result.result ?? result)}`);
    }
}

export function soql(query: string): any[] {
    const result = sfJson(['data', 'query', '--query', query]);
    if (result.status !== 0) {
        throw new Error(`SOQL query failed: ${JSON.stringify(result)}`);
    }
    return result.result.records;
}

export function saveOrgInfo(info: OrgInfo): void {
    fs.mkdirSync(AUTH_DIR, { recursive: true });
    fs.writeFileSync(ORG_INFO_PATH, JSON.stringify(info, null, 4));
}

export function orgInfo(): OrgInfo {
    return JSON.parse(fs.readFileSync(ORG_INFO_PATH, 'utf8'));
}
