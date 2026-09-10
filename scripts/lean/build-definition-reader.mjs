import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, relative, resolve } from 'node:path'

const root = resolve(import.meta.dirname, '../..')
const leanRoot = resolve(root, 'proofs/Mythroads')
const targets = [
    resolve(root, 'documents/engineering/lean-definitions.html'),
    resolve(root, 'public/lean-definitions.html'),
]

function leanFiles(directory) {
    return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
        const path = resolve(directory, entry.name)
        if (entry.isDirectory()) return leanFiles(path)
        return entry.name.endsWith('.lean') ? [path] : []
    })
}

const declarationPattern =
    /^(?:(private|protected)\s+)?(?:(partial|noncomputable)\s+)?(abbrev|inductive|structure|def|instance|mutual)\b(?:\s+([^\s:(]+))?/
const boundaryPattern =
    /^(?:(?:private|protected)\s+)?(?:(?:partial|noncomputable)\s+)?(?:abbrev|inductive|structure|def|instance|mutual|theorem)\b|^\/--|^end\b/

function documentationBefore(lines, declarationIndex) {
    let end = declarationIndex - 1
    while (end >= 0 && lines[end].trim() === '') end -= 1
    if (end < 0 || !lines[end].includes('-/')) return ''
    let start = end
    while (start >= 0 && !lines[start].includes('/--')) start -= 1
    if (start < 0) return ''
    const raw = lines.slice(start, end + 1).join('\n')
    if (!raw.trimStart().startsWith('/--')) return ''
    return raw
        .replace(/^\s*\/--\s?/, '')
        .replace(/\s?-\/\s*$/, '')
        .split('\n')
        .map((line) => line.replace(/^\s*\*?\s?/, ''))
        .join('\n')
        .trim()
}

function declarations(path) {
    const lines = readFileSync(path, 'utf8').split(/\r?\n/)
    const result = []
    for (let index = 0; index < lines.length; index += 1) {
        const match = lines[index].match(declarationPattern)
        if (!match) continue
        let end = index + 1
        while (end < lines.length && !boundaryPattern.test(lines[end])) end += 1
        const modifiers = [match[1], match[2]].filter(Boolean).join(' ')
        const kind = match[3]
        const name = kind === 'mutual' ? 'mutual definitions' : (match[4] ?? kind)
        result.push({
            kind: `${modifiers ? `${modifiers} ` : ''}${kind}`,
            name,
            documentation: documentationBefore(lines, index),
            code: lines.slice(index, end).join('\n').trimEnd(),
        })
        index = end - 1
    }
    return result
}

const modules = leanFiles(leanRoot)
    .map((path) => ({
        path: relative(root, path),
        name: relative(leanRoot, path)
            .replace(/\.lean$/, '')
            .replaceAll('/', '.'),
        declarations: declarations(path),
    }))
    .filter((module) => module.declarations.length > 0)
    .sort((left, right) => {
        if (left.name === 'Game.World') return -1
        if (right.name === 'Game.World') return 1
        const leftGroup = left.name.startsWith('Game.')
            ? 0
            : left.name.startsWith('Backend.')
              ? 1
              : 2
        const rightGroup = right.name.startsWith('Game.')
            ? 0
            : right.name.startsWith('Backend.')
              ? 1
              : 2
        return leftGroup - rightGroup || left.name.localeCompare(right.name)
    })

const count = modules.reduce((sum, module) => sum + module.declarations.length, 0)
const data = JSON.stringify(modules).replaceAll('<', '\\u003c')
const html = String.raw`<!doctype html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mythroads Lean definitions</title>
<style>
:root{color-scheme:dark;--bg:#0b1210;--panel:#131f1c;--line:#2b4039;--ink:#edf5e9;--muted:#91a79f;--mint:#67d9b4;--gold:#efca72;--rose:#f08d9a;--blue:#89c8ff}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.55 Inter,ui-sans-serif,system-ui,sans-serif}
.layout{display:grid;grid-template-columns:270px minmax(0,1000px);gap:36px;width:min(1340px,calc(100% - 36px));margin:auto;padding:28px 0 80px}
aside{position:sticky;top:20px;align-self:start;max-height:calc(100vh - 40px);overflow:auto}.brand{font:700 24px Georgia,serif}.meta{margin:5px 0 18px;color:var(--muted);font-size:12px}
input{width:100%;padding:11px 12px;border:1px solid var(--line);border-radius:9px;background:#09100e;color:var(--ink);font:inherit}
nav{margin-top:14px}nav button{display:block;width:100%;padding:7px 9px;border:0;border-radius:7px;background:none;color:var(--muted);text-align:left;cursor:pointer}nav button:hover,nav button.active{background:var(--panel);color:var(--mint)}
header{padding:24px 0 22px}.eyebrow{color:var(--mint);font-size:11px;font-weight:800;letter-spacing:.14em;text-transform:uppercase}h1{margin:5px 0 10px;font:700 clamp(38px,6vw,64px)/1 Georgia,serif;letter-spacing:-.035em}.lede{max-width:70ch;color:#bed0c9;font-size:17px}
.module{margin:22px 0 42px}.module>h2{margin:0 0 4px;font:700 29px Georgia,serif}.path{margin-bottom:15px;color:var(--muted);font:12px ui-monospace,monospace}
.definition{margin:10px 0;border:1px solid var(--line);border-radius:12px;background:var(--panel);overflow:hidden}.definition[hidden],.module[hidden]{display:none}
.guide{padding:20px;border:1px solid var(--line);border-radius:14px;background:linear-gradient(135deg,#14241f,#101a17)}.guide h2{margin:0 0 8px;font:700 25px Georgia,serif}.guide p{margin:7px 0;color:#bed0c9}.pipeline{display:flex;flex-wrap:wrap;align-items:center;gap:7px;margin:16px 0}.pipeline button{border:1px solid #3e6257;border-radius:8px;background:#0a1210;color:var(--mint);padding:8px 10px;font:600 12px ui-monospace,monospace;cursor:pointer}.arrow{color:var(--gold)}
summary{display:flex;align-items:center;gap:10px;padding:12px 15px;cursor:pointer;list-style:none}.kind{padding:2px 7px;border-radius:999px;background:#23463b;color:var(--mint);font-size:10px;font-weight:800;text-transform:uppercase}.name{font:600 14px ui-monospace,monospace}summary::after{content:'+';margin-left:auto;color:var(--muted)}details[open] summary::after{content:'−'}
.doc{margin:0;padding:15px 18px;border-top:1px solid var(--line);color:#c7d7d1;white-space:pre-wrap}pre{margin:0;overflow:auto;padding:17px 18px;border-top:1px solid var(--line);background:#070d0b;font:13px/1.58 ui-monospace,SFMono-Regular,Menlo,monospace;tab-size:2}.kw{color:var(--rose);font-weight:650}.str{color:var(--gold)}.num{color:var(--blue)}.comment{color:#6e857c;font-style:italic}.op{color:#98e5cd}
.empty{padding:40px 0;color:var(--muted)}@media(max-width:800px){.layout{display:block;width:min(100% - 22px,1000px)}aside{position:static;max-height:none}nav{display:none}header{padding-top:38px}}
</style>
</head>
<body>
<div class="layout"><aside><div class="eyebrow">Generated source index</div><div class="brand">Lean definitions</div><div class="meta">${count} definitions in ${modules.length} modules · proofs excluded</div><input id="search" type="search" placeholder="Search names or code…" aria-label="Search definitions"><nav id="modules"></nav></aside><main><header><div class="eyebrow">Mythroads model and backend</div><h1>Every definition. No proof commentary.</h1><p class="lede">This file is generated directly from <code>proofs/Mythroads</code>. Open a definition to read its exact Lean source. Search for <code>BoardGraph</code>, <code>roads</code>, <code>Combat</code>, <code>inventory</code>, or a Convex operation.</p></header><section class="guide"><h2>Where game state changes</h2><p>Lean describes functions as <code>Function</code> values containing <code>Statement</code> and <code>Expr</code> trees. The emitter converts those trees to TypeScript.</p><div class="pipeline"><button type="button" data-find="dispatchEndpoint">public dispatch</button><span class="arrow">→</span><button type="button" data-find="executeEndpoint">internal execute</button><span class="arrow">→</span><button type="button" data-find="authorizeEvent">authorize</button><span class="arrow">→</span><button type="button" data-find="routeEvent">route handler</button><span class="arrow">→</span><button type="button" data-find="persistEvent">persist event</button></div><p><code>game.execute</code> is the single transactional write boundary. Routed handlers alter normalized room, player, combat, encounter, selection, camera, and inventory records through generated <code>ctx.db</code> statements.</p></section><div id="content"></div></main></div>
<script id="lean-data" type="application/json">${data}</script>
<script>
const modules=JSON.parse(document.querySelector('#lean-data').textContent);const content=document.querySelector('#content');const nav=document.querySelector('#modules');
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const pattern=/(--[^\n]*|\/-[\s\S]*?-\/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:abbrev|inductive|structure|def|instance|mutual|private|protected|where|deriving|namespace|fun|if|then|else|match|with|some|none|true|false|by|let|do|return)\b|\b\d+\b|:=|=>|→|←|≠|≤|≥|∧|∨|∀)/g;
function highlight(source){let cursor=0,out='';for(const match of source.matchAll(pattern)){out+=esc(source.slice(cursor,match.index));const value=match[0];const kind=value.startsWith('--')||value.startsWith('/-')?'comment':/^[\"']/.test(value)?'str':/^\d+$/.test(value)?'num':/^[A-Za-z]/.test(value)?'kw':'op';out+='<span class="'+kind+'">'+esc(value)+'</span>';cursor=match.index+value.length}return out+esc(source.slice(cursor))}
for(const module of modules){const section=document.createElement('section');section.className='module';section.id=module.name.replaceAll('.','-');section.dataset.search=(module.name+' '+module.path+' '+module.declarations.map(value=>value.name+' '+value.documentation+' '+value.code).join(' ')).toLowerCase();section.innerHTML='<h2>'+esc(module.name)+'</h2><div class="path">'+esc(module.path)+'</div>';for(const value of module.declarations){const details=document.createElement('details');details.className='definition';details.dataset.search=(module.name+' '+value.kind+' '+value.name+' '+value.documentation+' '+value.code).toLowerCase();const docs=value.documentation?'<p class="doc">'+esc(value.documentation)+'</p>':'';details.innerHTML='<summary><span class="kind">'+esc(value.kind)+'</span><span class="name">'+esc(value.name)+'</span></summary>'+docs+'<pre><code>'+highlight(value.code)+'</code></pre>';if(value.name==='BoardGraph')details.open=true;section.append(details)}content.append(section);const button=document.createElement('button');button.textContent=module.name+' ('+module.declarations.length+')';button.onclick=()=>{section.scrollIntoView();document.querySelectorAll('nav button').forEach(item=>{item.classList.remove('active')});button.classList.add('active')};nav.append(button)}
document.querySelector('#search').addEventListener('input',event=>{const query=event.target.value.trim().toLowerCase();let visible=0;for(const section of document.querySelectorAll('.module')){let moduleVisible=false;for(const definition of section.querySelectorAll('.definition')){const match=!query||definition.dataset.search.includes(query);definition.hidden=!match;moduleVisible||=match;if(match)visible++}section.hidden=!moduleVisible}document.title=visible+' Lean definitions · Mythroads'});
for(const button of document.querySelectorAll('[data-find]'))button.addEventListener('click',()=>{const search=document.querySelector('#search');search.value=button.dataset.find;search.dispatchEvent(new Event('input'));document.querySelector('.module:not([hidden])')?.scrollIntoView()});
</script>
</body>
</html>
`

if (process.argv.includes('--check')) {
    if (targets.some((target) => !existsSync(target) || readFileSync(target, 'utf8') !== html)) {
        process.stderr.write('lean-definitions.html is stale. Run npm run docs:lean.\n')
        process.exit(1)
    }
    process.stdout.write(`Lean definition reader contains ${count} current definitions.\n`)
} else {
    for (const target of targets) {
        mkdirSync(dirname(target), { recursive: true })
        writeFileSync(target, html)
    }
    process.stdout.write(`Generated ${count} Lean definitions for documentation and /lean.\n`)
}
