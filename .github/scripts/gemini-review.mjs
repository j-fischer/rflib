// Reviews a pull request with Gemini and posts the findings as a GitHub review
// with line-by-line comments. Runs in the "Gemini Code Review" workflow.
//
// The first review of a PR covers the whole diff. Later runs only review the
// commits pushed since the last Gemini review, so earlier comments are not
// repeated; after a force push the whole diff is reviewed again.

import { readFile } from 'node:fs/promises';

const GITHUB_API = 'https://api.github.com';
const GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta';
const REVIEW_MARKER = '<!-- gemini-review -->';
const BOT_LOGIN = 'github-actions[bot]';
const MAX_DIFF_CHARS = 400_000;
const MAX_COMMENTS = 25;
const IGNORED_FILES = [/(^|\/)package-lock\.json$/, /\.snap$/, /\/staticresources\//, /\.(svg|png|jpg|gif|pdf)$/i];
const SEVERITY_LABELS = {
    critical: '🔴 **Critical**',
    major: '🟠 **Major**',
    minor: '🟡 **Minor**',
    nit: '⚪ **Nit**'
};
const SEVERITY_ORDER = Object.keys(SEVERITY_LABELS);

const RESPONSE_SCHEMA = {
    type: 'OBJECT',
    properties: {
        summary: { type: 'STRING' },
        comments: {
            type: 'ARRAY',
            items: {
                type: 'OBJECT',
                properties: {
                    path: { type: 'STRING' },
                    line: { type: 'INTEGER' },
                    severity: { type: 'STRING', enum: SEVERITY_ORDER },
                    body: { type: 'STRING' }
                },
                required: ['path', 'line', 'severity', 'body']
            }
        }
    },
    required: ['summary', 'comments']
};

const { GITHUB_TOKEN, GEMINI_API_KEY, GITHUB_REPOSITORY, GITHUB_EVENT_PATH } = process.env;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-4-argon';

async function github(path, options = {}) {
    const response = await fetch(`${GITHUB_API}/repos/${GITHUB_REPOSITORY}${path}`, {
        ...options,
        headers: {
            Accept: 'application/vnd.github+json',
            Authorization: `Bearer ${GITHUB_TOKEN}`,
            'X-GitHub-Api-Version': '2022-11-28',
            ...(options.body ? { 'Content-Type': 'application/json' } : {})
        }
    });
    if (!response.ok) {
        throw new Error(`GitHub ${options.method || 'GET'} ${path} failed: ${response.status} ${await response.text()}`);
    }
    return response.json();
}

async function githubPaged(path) {
    const results = [];
    for (let page = 1; ; page++) {
        const separator = path.includes('?') ? '&' : '?';
        const items = await github(`${path}${separator}per_page=100&page=${page}`);
        results.push(...items);
        if (items.length < 100) {
            return results;
        }
    }
}

// Returns the new-file line numbers of the lines a patch adds.
function addedLines(patch) {
    const lines = new Set();
    let newLine = 0;
    for (const raw of patch.split('\n')) {
        const hunk = raw.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
        if (hunk) {
            newLine = Number(hunk[1]);
        } else if (raw.startsWith('+')) {
            lines.add(newLine++);
        } else if (raw.startsWith(' ')) {
            newLine++;
        }
    }
    return lines;
}

// Renders a patch with the line number in front of every line Gemini may comment on.
function annotatePatch(patch, commentable) {
    let newLine = 0;
    return patch
        .split('\n')
        .map((raw) => {
            const hunk = raw.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
            if (hunk) {
                newLine = Number(hunk[1]);
                return raw;
            }
            if (raw.startsWith('+') || raw.startsWith(' ')) {
                const line = newLine++;
                return `${commentable.has(line) ? String(line).padStart(6) : ''.padStart(6)} ${raw}`;
            }
            return `${''.padStart(6)} ${raw}`;
        })
        .join('\n');
}

// Finds the commit of the last Gemini review and, when the PR head has only moved forward
// since then, the lines added after it. Returns null when the whole diff needs a review.
async function findIncrementalScope(pr) {
    const reviews = await githubPaged(`/pulls/${pr.number}/reviews`);
    const lastReview = reviews
        .filter((review) => review.user?.login === BOT_LOGIN && review.body?.includes(REVIEW_MARKER))
        .at(-1);
    if (!lastReview) {
        return null;
    }

    const comparison = await github(`/compare/${lastReview.commit_id}...${pr.head.sha}`);
    if (comparison.status === 'identical') {
        return { base: lastReview.commit_id, lines: new Map() };
    }
    if (comparison.status !== 'ahead') {
        return null;
    }
    const lines = new Map(
        (comparison.files || []).filter((file) => file.patch).map((file) => [file.filename, addedLines(file.patch)])
    );
    return { base: lastReview.commit_id, lines };
}

function buildDiff(files, scope) {
    const sections = [];
    const commentableByFile = new Map();
    const skipped = [];
    let size = 0;

    for (const file of files) {
        if (!file.patch || IGNORED_FILES.some((pattern) => pattern.test(file.filename))) {
            continue;
        }
        const added = addedLines(file.patch);
        const inScope = scope ? scope.lines.get(file.filename) || new Set() : added;
        const commentable = new Set([...added].filter((line) => inScope.has(line)));
        if (commentable.size === 0) {
            continue;
        }

        const section = `### File: ${file.filename} (${file.status})\n\`\`\`diff\n${annotatePatch(file.patch, commentable)}\n\`\`\``;
        if (size + section.length > MAX_DIFF_CHARS) {
            skipped.push(file.filename);
            continue;
        }
        size += section.length;
        sections.push(section);
        commentableByFile.set(file.filename, commentable);
    }
    return { text: sections.join('\n\n'), commentableByFile, skipped };
}

async function callGemini(systemInstruction, prompt) {
    const request = {
        systemInstruction: { parts: [{ text: systemInstruction }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: 'application/json', responseSchema: RESPONSE_SCHEMA }
    };

    for (let attempt = 1; ; attempt++) {
        const response = await fetch(`${GEMINI_API}/models/${GEMINI_MODEL}:generateContent`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
            body: JSON.stringify(request),
            signal: AbortSignal.timeout(10 * 60 * 1000)
        });
        if (response.ok) {
            const data = await response.json();
            const text = (data.candidates?.[0]?.content?.parts || [])
                .filter((part) => !part.thought && part.text)
                .map((part) => part.text)
                .join('');
            if (!text) {
                throw new Error(`Gemini returned no content: ${JSON.stringify(data.promptFeedback || data.candidates?.[0])}`);
            }
            return JSON.parse(text.replace(/^```(?:json)?\s*|\s*```$/g, ''));
        }
        const retryable = response.status === 429 || response.status >= 500;
        if (!retryable || attempt === 3) {
            throw new Error(`Gemini request failed: ${response.status} ${await response.text()}`);
        }
        console.log(`Gemini returned ${response.status}, retrying (attempt ${attempt})...`);
        await new Promise((resolve) => setTimeout(resolve, attempt * 15_000));
    }
}

function formatComment(comment) {
    return `${SEVERITY_LABELS[comment.severity] || SEVERITY_LABELS.minor} ${comment.body}`;
}

async function main() {
    const event = JSON.parse(await readFile(GITHUB_EVENT_PATH, 'utf8'));
    const pr = event.pull_request;

    const scope = await findIncrementalScope(pr);
    if (scope && scope.lines.size === 0) {
        console.log(`Commit ${pr.head.sha} was already reviewed. Nothing to do.`);
        return;
    }

    const files = await githubPaged(`/pulls/${pr.number}/files`);
    const diff = buildDiff(files, scope);
    if (diff.commentableByFile.size === 0) {
        console.log('No reviewable changes. Nothing to do.');
        return;
    }

    const [instructions, projectContext] = await Promise.all([
        readFile('.github/gemini-review/instructions.md', 'utf8'),
        readFile('CLAUDE.md', 'utf8').catch(() => '')
    ]);
    const scopeNote = scope
        ? `This is a follow-up review: only the lines added since commit ${scope.base} are numbered. ` +
          'Earlier changes were already reviewed; unnumbered lines are context only.'
        : 'This is the first review of this pull request.';
    const prompt = [
        `# Pull request #${pr.number}: ${pr.title}`,
        pr.body ? `## Description\n${pr.body}` : '',
        projectContext ? `## Project context\n${projectContext}` : '',
        `## Diff\n${scopeNote}\n\n${diff.text}`
    ]
        .filter(Boolean)
        .join('\n\n');

    console.log(`Reviewing ${diff.commentableByFile.size} file(s) with ${GEMINI_MODEL}...`);
    const result = await callGemini(instructions, prompt);

    const placed = [];
    const unplaced = [];
    for (const comment of result.comments || []) {
        const target = diff.commentableByFile.get(comment.path)?.has(comment.line) ? placed : unplaced;
        target.push(comment);
    }
    const bySeverity = (a, b) => SEVERITY_ORDER.indexOf(a.severity) - SEVERITY_ORDER.indexOf(b.severity);
    const inline = placed.sort(bySeverity).slice(0, MAX_COMMENTS);
    const dropped = placed.length - inline.length;

    if (scope && inline.length === 0 && unplaced.length === 0) {
        console.log('No findings in the new commits. Skipping the review.');
        return;
    }

    const reviewScope = scope ? `changes since ${scope.base.slice(0, 7)}` : 'full pull request';
    const body = [
        REVIEW_MARKER,
        `## Gemini code review`,
        `_Model: \`${GEMINI_MODEL}\` · Scope: ${reviewScope} · ${inline.length} inline comment(s)_`,
        result.summary,
        unplaced.length
            ? `### Comments outside the diff\n${unplaced.map((c) => `- \`${c.path}:${c.line}\` ${formatComment(c)}`).join('\n')}`
            : '',
        dropped ? `_${dropped} lower-severity comment(s) omitted to keep the review short._` : '',
        diff.skipped.length ? `_Not reviewed (diff too large): ${diff.skipped.map((f) => `\`${f}\``).join(', ')}_` : ''
    ]
        .filter(Boolean)
        .join('\n\n');

    await github(`/pulls/${pr.number}/reviews`, {
        method: 'POST',
        body: JSON.stringify({
            commit_id: pr.head.sha,
            event: 'COMMENT',
            body,
            comments: inline.map((c) => ({ path: c.path, line: c.line, side: 'RIGHT', body: formatComment(c) }))
        })
    });
    console.log(`Posted review with ${inline.length} inline comment(s).`);
}

await main();
