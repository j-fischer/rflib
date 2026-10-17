#!/usr/bin/env node
/**
 * PR inventory for rflib-pr: groups a branch's changes into the bottom-up layers the PR
 * description walks through, flags review hotspots with GitHub permalinks, and maps source
 * to tests. Read-only: runs git (and `gh pr view` when available), never writes anything.
 *
 *   node .claude/skills/rflib-pr/inventory.mjs [--base origin/master]
 */
import { execFileSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';

const args = process.argv.slice(2);
const baseRef = args.includes('--base') ? args[args.indexOf('--base') + 1] : 'origin/master';

const run = (cmd, cmdArgs, { allowFail = false } = {}) => {
    try {
        return execFileSync(cmd, cmdArgs, { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'] }).trim();
    } catch (error) {
        if (allowFail) return null;
        throw error;
    }
};
const git = (...gitArgs) => run('git', gitArgs);

const branch = git('rev-parse', '--abbrev-ref', 'HEAD');
const head = git('rev-parse', 'HEAD');
const mergeBase = git('merge-base', baseRef, 'HEAD');
const remoteUrl = run('git', ['remote', 'get-url', 'origin'], { allowFail: true }) || '';
const repoSlug = (remoteUrl.match(/github\.com[:/](.+?)(?:\.git)?$/) || [])[1] || 'j-fischer/rflib';
const blobBase = `https://github.com/${repoSlug}/blob/${head}/`;

// ---------- packages (from sfdx-project.json, so new package dirs are picked up) ----------
const project = existsSync('sfdx-project.json') ? JSON.parse(readFileSync('sfdx-project.json', 'utf8')) : { packageDirectories: [] };
const packageDirs = project.packageDirectories.map((dir) => ({ path: dir.path, name: dir.package, version: dir.versionNumber }));
const packageOf = (file) => packageDirs.find((dir) => file.startsWith(`${dir.path}/`));

// ---------- layers, in the bottom-up order the PR description uses ----------
const LAYERS = [
    ['data', '1. Data model', /\/(objects|customMetadata|globalValueSets|standardValueSets)\//],
    ['security', '2. Security & access', /\/(permissionsets|permissionsetgroups|customPermissions|profiles|sharingRules|roles)\//],
    ['backend', '3. Services & backend (Apex)', /\/(classes|triggers)\//],
    ['integration', '4. Integration & automation', /(\/(flows|platformEventChannels|platformEventChannelMembers|namedCredentials|externalCredentials|remoteSiteSettings|cspTrustedSites|connectedApps|notificationTypes)\/|^(aws|azure|otel|node)\/)/],
    ['frontend', '5. Front end', /\/(lwc|aura|pages|components|staticresources|flexipages|tabs|applications|layouts|quickActions|labels|messageChannels)\//],
    ['tests', '6. Tests', /(\/test\/default\/|__tests__\/|^e2e\/|Test\.cls$)/],
    ['release', '7. Docs & release', /(^CHANGELOG\.md$|^README\.md$|^sfdx-project\.json$|^package\.json$|\.md$)/],
    ['tooling', '8. Tooling & other', /.*/]
];
const layerOf = (file) => {
    if (LAYERS[5][2].test(file)) return 'tests'; // tests win over the folder they live in (classes/, lwc/)
    return LAYERS.find(([, , pattern]) => pattern.test(file))[0];
};

// Fold bundles (LWC/Aura) and *-meta.xml companions into one row per logical unit.
const unitOf = (file) => {
    const bundle = file.match(/^(.*\/(?:lwc|aura)\/[^/]+)\/(?!__tests__)/);
    if (bundle) return bundle[1] + '/';
    return file.replace(/\.(cls|trigger)-meta\.xml$/, '.$1');
};

// ---------- file stats ----------
// No rename detection: in Salesforce a renamed file is a deleted component plus a new one.
const statusByFile = new Map(
    git('diff', '--name-status', '--no-renames', mergeBase, 'HEAD')
        .split('\n')
        .filter(Boolean)
        .map((line) => line.split('\t').reverse())
);
const numstat = git('diff', '--numstat', '--no-renames', mergeBase, 'HEAD')
    .split('\n')
    .filter(Boolean)
    .map((line) => {
        const [added, removed, file] = line.split('\t');
        return { file, added: added === '-' ? 0 : Number(added), removed: removed === '-' ? 0 : Number(removed), status: statusByFile.get(file)[0] };
    });

const units = new Map();
for (const entry of numstat) {
    const key = unitOf(entry.file);
    const unit = units.get(key) || { unit: key, layer: layerOf(entry.file), added: 0, removed: 0, statuses: new Set(), files: 0 };
    unit.added += entry.added;
    unit.removed += entry.removed;
    unit.statuses.add(entry.status);
    unit.files += 1;
    units.set(key, unit);
}

// ---------- added lines with their new-file line numbers ----------
const addedLines = []; // { file, line, text }
{
    let file = null;
    let lineNo = 0;
    for (const raw of git('diff', '-U0', '--no-color', '--no-ext-diff', '--no-renames', mergeBase, 'HEAD').split('\n')) {
        if (raw.startsWith('+++ ')) file = raw === '+++ /dev/null' ? null : raw.slice(6);
        else if (raw.startsWith('@@')) lineNo = Number(raw.match(/\+(\d+)/)[1]);
        else if (file && raw.startsWith('+')) addedLines.push({ file, line: lineNo++, text: raw.slice(1) });
    }
}

// ---------- hotspots ----------
const isTest = (file) => layerOf(file) === 'tests';
const CODE_RULES = [
    [/\.(cls|trigger)$/, /\bwithout sharing\b|\.withoutSharing\(\)/, 'Runs `without sharing` — record sharing is bypassed'],
    // rflib_SOQL (the bundled SOQL library) switches access mode with .systemMode() rather than a SYSTEM_MODE literal
    [/\.(cls|trigger)$/, /\bSYSTEM_MODE\b|\.systemMode\(\)/, 'SYSTEM_MODE access — user CRUD/FLS is not enforced'],
    [/\.(cls|trigger)$/, /Database\.(query|queryWithBinds|countQuery|getQueryLocator)\s*\(/, 'Dynamic SOQL — check bind usage / injection'],
    [/\.(cls|trigger)$/, /^\s*global\b/, '`global` member — package API surface, hard to change later'],
    [/\.(cls|trigger)$/, /@(InvocableMethod|RestResource|Http(Get|Post|Put|Patch|Delete))\b/, 'External entry point (Flow / REST)'],
    [/\.(cls|trigger)$/, /EventBus\.publish\s*\(/, 'Publishes Platform Events — check limits and publish behaviour'],
    [/\.(cls|trigger)$/, /\bnew Http(Request)?\s*\(|['"]callout:/, 'HTTP callout'],
    [/\.(cls|trigger)$/, /@future\b|System\.enqueueJob\s*\(|implements\s+[^{]*(Queueable|Database\.Batchable|Schedulable)/, 'Asynchronous processing'],
    [/\.(cls|trigger)$/, /FeatureManagement\.checkPermission\s*\(/, 'Custom Permission gate'],
    [/\.(cls|trigger)$/, /Test\.isRunningTest\s*\(/, '`Test.isRunningTest()` in production code'],
    [/\.js$/, /innerHTML|lwc:dom|eval\s*\(/, 'Raw DOM / eval — check for XSS'],
    [/\.html$/, /lwc:dom="manual"/, 'Manual DOM rendering — check for XSS'],
    [/\.js$/, /\bsubscribe\s*\(|lightning\/empApi/, 'Streaming subscription — check unsubscribe on disconnect'],
    [/./, /\b(TODO|FIXME|HACK|XXX)\b/, 'Leftover TODO/FIXME']
];
const hotspots = new Map(); // key file|label -> { file, line, label, count }
const addHotspot = (file, line, label) => {
    const key = `${file}|${label}`;
    const existing = hotspots.get(key);
    if (existing) existing.count += 1;
    else hotspots.set(key, { file, line, label, count: 1 });
};
addedLines.forEach(({ file, line, text }, index) => {
    if (isTest(file) || /\/rflib_SOQL\.cls$/.test(file)) return; // vendored library: flagged once below, not per line
    for (const [filePattern, linePattern, label] of CODE_RULES) {
        if (filePattern.test(file) && linePattern.test(text)) addHotspot(file, line, label);
    }
    // @AuraEnabled methods only (the annotation is also used on DTO properties)
    if (/\.cls$/.test(file) && /@AuraEnabled/.test(text)) {
        const next = addedLines[index + 1];
        const signature = /\bstatic\b.*\(/.test(text) ? text : next && next.file === file && next.line === line + 1 ? next.text : '';
        if (/\bstatic\b.*\(/.test(signature)) addHotspot(file, line, '`@AuraEnabled` method — LWC-callable entry point, check access checks');
    }
    if (/\/permissionsets\//.test(file) && /<(modifyAllRecords|viewAllRecords|modifyAllData|viewAllData)>true/.test(text)) {
        addHotspot(file, line, 'Elevated grant (View/Modify All)');
    }
    if (/\.js-meta\.xml$/.test(file) && /<isExposed>true/.test(text)) {
        addHotspot(file, line, 'Exposed in App Builder — `targetConfigs` are public configuration');
    }
});
for (const entry of numstat) {
    if (entry.status === 'D') addHotspot(entry.file, 0, 'Deleted — destructive change for installed orgs');
    if (/\/objects\/[^/]+__b\//.test(entry.file) && entry.status !== 'A') addHotspot(entry.file, 0, 'Existing Big Object changed — index is immutable once deployed');
    if (/\/flows\/.*\.flow-meta\.xml$/.test(entry.file)) addHotspot(entry.file, 0, 'Flow XML — reviewers cannot read this diff; describe the behaviour');
    if (entry.file === 'sfdx-project.json') addHotspot(entry.file, 0, 'Package versions / dependencies changed');
    if (/\/rflib_SOQL\.cls$/.test(entry.file)) addHotspot(entry.file, 0, 'Bundled SOQL library changed — vendored code, review against the upstream release');
    if (!isTest(entry.file) && /\.(cls|js|ts|mjs)$/.test(entry.file) && entry.added >= 300) {
        addHotspot(entry.file, 0, `Large change (+${entry.added}) — walk the reviewer through its structure`);
    }
}

// ---------- source -> test map ----------
const tracked = new Set(git('ls-files').split('\n'));
const changed = new Set(numstat.map((entry) => entry.file));
const testRows = [];
for (const entry of numstat) {
    if (isTest(entry.file) || entry.status === 'D') continue;
    const apex = entry.file.match(/([^/]+)\.cls$/);
    if (apex) {
        const source = readFileSync(entry.file, 'utf8');
        const isInterface = /\binterface\s+\w+/.test(source.replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, '')) && !/\bclass\s+\w+/.test(source.replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, ''));
        const testFile = [...tracked].find((file) => file.endsWith(`/${apex[1]}Test.cls`));
        testRows.push([apex[1], isInterface ? 'interface — no test needed' : testFile ? `${testFile.split('/').pop()}${changed.has(testFile) ? ' (changed)' : ' (unchanged!)'}` : '**none**']);
    }
    const lwc = entry.file.match(/\/lwc\/([^/]+)\/\1\.js$/);
    if (lwc) {
        const testFile = entry.file.replace(/[^/]+\.js$/, `__tests__/${lwc[1]}.test.js`);
        testRows.push([lwc[1], tracked.has(testFile) ? `${lwc[1]}.test.js${changed.has(testFile) ? ' (changed)' : ' (unchanged!)'}` : '**none**']);
    }
}

// ---------- LWC -> Apex wiring (the integration seam between front end and backend) ----------
const wiring = new Map();
for (const { file, text } of addedLines) {
    const match = text.match(/from\s+['"]@salesforce\/apex\/([\w.]+)['"]/);
    const component = (file.match(/\/(?:lwc|aura)\/([^/]+)\//) || [])[1];
    if (match && component && !isTest(file)) wiring.set(component, [...(wiring.get(component) || []), match[1]]);
}

// ---------- branch state ----------
const commits = git('log', '--no-merges', '--format=%h %s', `${mergeBase}..HEAD`).split('\n').filter(Boolean);
const upstream = run('git', ['rev-parse', '--abbrev-ref', '@{u}'], { allowFail: true });
const unpushed = upstream ? Number(git('rev-list', '--count', `${upstream}..HEAD`)) : null;
const behind = Number(git('rev-list', '--count', `HEAD..${baseRef}`));
const localBase = baseRef.replace(/^origin\//, '');
// Unpushed commits on local master that the branch was cut from: GitHub will ship them in this PR.
const localOnlyBase = baseRef.startsWith('origin/') ? run('git', ['log', '--format=%h %s', `${baseRef}..${localBase}`], { allowFail: true }) : null;
const inheritedCommits = (localOnlyBase || '').split('\n').filter((line) => line && commits.includes(line));
const dirty = git('status', '--porcelain');
const existingPr = run('gh', ['pr', 'view', branch, '--repo', repoSlug, '--json', 'number,url,state,title'], { allowFail: true });

// ---------- output ----------
const out = [];
const link = (file, line) => `[${file.split('/').pop()}${line ? `:${line}` : ''}](${blobBase}${file}${line ? `#L${line}` : ''})`;
const totalAdded = numstat.reduce((sum, entry) => sum + entry.added, 0);
const totalRemoved = numstat.reduce((sum, entry) => sum + entry.removed, 0);
const touchedPackages = [...new Set(numstat.map((entry) => packageOf(entry.file)).filter(Boolean))];
// Title comes from the branch's own lead commit: the oldest feat, else the oldest fix, else the oldest commit.
const ownSubjects = commits.filter((commit) => !inheritedCommits.includes(commit)).reverse().map((commit) => commit.replace(/^\S+ /, ''));
const firstSubject = ownSubjects.find((subject) => /^feat\b/.test(subject)) || ownSubjects.find((subject) => /^fix\b/.test(subject)) || ownSubjects[0] || '';
const type = (firstSubject.match(/^(\w+)/) || [])[1];

out.push(`# PR inventory: ${branch} → ${baseRef}`);
out.push('');
out.push(`- Repo: ${repoSlug} · merge base \`${mergeBase.slice(0, 7)}\` · HEAD \`${head.slice(0, 7)}\``);
out.push(`- ${commits.length} commit(s), ${numstat.length} file(s), +${totalAdded} −${totalRemoved}`);
out.push(`- Packages: ${touchedPackages.map((dir) => `${dir.name} (\`${dir.path}/\`, ${dir.version})`).join(', ') || 'none (repo tooling only)'}`);
// The CHANGELOG names the release the change targets; sfdx-project.json is only bumped when the package is cut.
const changelogHeading = existsSync('CHANGELOG.md') ? (readFileSync('CHANGELOG.md', 'utf8').match(/^###\s+(.+)$/m) || [])[1] : null;
if (changelogHeading) out.push(`- CHANGELOG top section: ${changelogHeading}${changed.has('CHANGELOG.md') ? ' (added or edited on this branch)' : ''}`);
out.push(`- Suggested title: \`${firstSubject}\`${ownSubjects.length > 1 ? ' (lead commit — rewrite if the branch does more)' : ''}`);
out.push(`- Suggested label: ${type === 'feat' ? '`enhancement`' : type === 'fix' ? '`bug`' : '(none — only feat/fix get one)'}`);
out.push(`- Permalink base: ${blobBase}`);
out.push('');
out.push('## Branch state');
out.push('');
out.push(`- Working tree: ${dirty ? `**dirty** — ${dirty.split('\n').length} uncommitted path(s) will NOT be in the PR` : 'clean'}`);
out.push(`- Upstream: ${upstream ? `${upstream}${unpushed ? ` (**${unpushed} commit(s) not pushed**)` : ' (up to date)'}` : '**none** — branch was never pushed'}`);
out.push(`- Behind ${baseRef}: ${behind ? `**${behind} commit(s)** — rebase before opening` : '0'}`);
if (inheritedCommits.length) out.push(`- **Inherited from unpushed local \`${localBase}\`** — these ship in this PR unless \`${localBase}\` is pushed first:\n${inheritedCommits.map((line) => `  - ${line}`).join('\n')}`);
out.push(`- Existing PR: ${existingPr ? (({ number, url, state }) => `#${number} ${state} ${url}`)(JSON.parse(existingPr)) : 'none'}`);
out.push('');
out.push('## Commits (oldest first)');
out.push('');
[...commits].reverse().forEach((commit) => out.push(`- ${commit}`));
out.push('');
out.push('## Changes by layer (bottom-up)');
for (const [key, title] of LAYERS) {
    const rows = [...units.values()].filter((unit) => unit.layer === key);
    if (!rows.length) continue;
    out.push('');
    out.push(`### ${title}`);
    out.push('');
    out.push('| Status | +/− | Path |');
    out.push('|---|---|---|');
    rows.forEach((unit) => out.push(`| ${[...unit.statuses].join('')} | +${unit.added} −${unit.removed} | \`${unit.unit}\`${unit.files > 1 ? ` (${unit.files} files)` : ''} |`));
}
if (wiring.size) {
    out.push('');
    out.push('### Front end → Apex wiring');
    out.push('');
    wiring.forEach((methods, component) => out.push(`- \`${component}\` → ${[...new Set(methods)].map((method) => `\`${method}\``).join(', ')}`));
}
out.push('');
out.push('## Review hotspots (non-test code)');
out.push('');
if (hotspots.size) {
    out.push('| Where | Signal |');
    out.push('|---|---|');
    [...hotspots.values()].forEach(({ file, line, label, count }) => out.push(`| ${link(file, line)} | ${label}${count > 1 ? ` (×${count}, first shown)` : ''} |`));
} else {
    out.push('None detected by pattern — still read the diff.');
}
out.push('');
out.push('## Source → test map');
out.push('');
if (testRows.length) {
    out.push('| Source | Test |');
    out.push('|---|---|');
    testRows.forEach(([source, test]) => out.push(`| \`${source}\` | ${test} |`));
} else {
    out.push('No Apex classes or LWC modules changed.');
}

console.log(out.join('\n'));
