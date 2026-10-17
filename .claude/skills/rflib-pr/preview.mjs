#!/usr/bin/env node
/**
 * Renders a PR body through GitHub's markdown API (the renderer pull requests use) into a standalone HTML page,
 * with GitHub's stylesheet and Mermaid rendered client-side the way github.com does it. Read-only on GitHub:
 * POST /markdown publishes nothing.
 *
 *   node .claude/skills/rflib-pr/preview.mjs [body.md]            write <body>.preview.html once and report
 *   node .claude/skills/rflib-pr/preview.mjs --serve [body.md]    serve it on http://localhost:4799/, re-rendered
 *                                                                 on every reload (.claude/launch.json: rflib-pr-preview)
 *
 * body.md defaults to .claude/skills/rflib-pr/out/pr-body.md.
 */
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';

const PORT = 4799;
const GITHUB_BODY_LIMIT = 65536;

const args = process.argv.slice(2);
const serve = args.includes('--serve');
const bodyFile = args.find((arg) => !arg.startsWith('--')) || '.claude/skills/rflib-pr/out/pr-body.md';

if (!existsSync(bodyFile)) {
    console.error(`No PR body at ${bodyFile}. Usage: node .claude/skills/rflib-pr/preview.mjs [--serve] [body.md]`);
    process.exit(1);
}

function render() {
    const markdown = readFileSync(bodyFile, 'utf8');
    const html = execFileSync('gh', ['api', 'markdown', '-f', 'mode=gfm', '-f', 'context=j-fischer/rflib', '-F', `text=@${bodyFile}`], {
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024
    });

    const rawTableRows = (html.match(/^\|.*\|$/gm) || []).length;
    const report = [
        `Body: ${markdown.length} chars${markdown.length > GITHUB_BODY_LIMIT ? ` — OVER the GitHub limit of ${GITHUB_BODY_LIMIT}, trim it` : ` (GitHub limit ${GITHUB_BODY_LIMIT})`}`,
        `Tables: ${(html.match(/<table/g) || []).length} rendered${rawTableRows ? `, ${rawTableRows} raw | rows left unrendered — a table is broken` : ''}`,
        `Mermaid diagrams: ${(html.match(/data-type="mermaid"/g) || []).length}`
    ];

    const page = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PR preview</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css@5.5.1/github-markdown-light.min.css">
<style>
  body { margin: 0; background: #ffffff; }
  .markdown-body { box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 32px 16px; }
  .js-render-enrichment-loader { display: none !important; }
</style>
</head>
<body>
<article class="markdown-body">
${html}
</article>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.esm.min.mjs';
  // GitHub emits Mermaid as an enrichment <section> holding the raw source; swap in a renderable node.
  document.querySelectorAll('section[data-type="mermaid"]').forEach((section) => {
    const diagram = document.createElement('pre');
    diagram.className = 'mermaid';
    diagram.textContent = section.querySelector('pre[lang="mermaid"]').textContent;
    section.replaceWith(diagram);
  });
  mermaid.initialize({ startOnLoad: false, theme: 'default' });
  try {
    await mermaid.run();
    document.body.dataset.mermaid = 'ok';
  } catch (error) {
    document.body.dataset.mermaid = 'error: ' + error.message;
  }
</script>
</body>
</html>
`;
    return { page, report };
}

if (serve) {
    createServer((request, response) => {
        if (request.url !== '/') {
            response.writeHead(404).end();
            return;
        }
        try {
            const { page, report } = render();
            console.log(`[${new Date().toISOString()}] rendered ${bodyFile} — ${report.join(' · ')}`);
            response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(page);
        } catch (error) {
            console.error(error.message);
            response.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' }).end(error.message);
        }
    }).listen(PORT, () => console.log(`Serving the preview of ${bodyFile} on http://localhost:${PORT}/ (re-rendered on every reload)`));
} else {
    const { page, report } = render();
    const previewFile = bodyFile.replace(/\.md$/, '') + '.preview.html';
    writeFileSync(previewFile, page);
    console.log(`Preview: ${pathToFileURL(previewFile).href}`);
    report.forEach((line) => console.log(line));
}
