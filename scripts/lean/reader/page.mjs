/**
 * Assembles the single-file HTML reader.
 *
 * The page is rendered here rather than in the browser: every declaration is real markup with a
 * real anchor, so a link into the middle of the engine works with JavaScript switched off and the
 * browser's own find-in-page searches the actual source. The inline script only adds the three
 * things that need a runtime — filtering, the theme toggle, and the `/` shortcut.
 *
 * Each chapter is one Lean module. Its `/-! -/` blocks become the chapter's prose, its definitions
 * become cards, and its theorems are collected into a closing section with the axioms each proof
 * depends on, because "what is proved here" is a different question from "what is defined here".
 */

import { highlightLean } from './lean.mjs'
import { escapeHtml, markdown } from './markdown.mjs'
import { bodyOf, declarationId, isKernelChecked, proofOf, statementOf } from './model.mjs'
import { style } from './style.mjs'

const attribute = (text) => escapeHtml(text).replaceAll('\n', ' ')

/** The name shown on a card: fully qualified, minus the part namespace it obviously sits in. */
const displayName = (name) =>
    name.replace(/^Mythroads\./, '').replace(/^(Engine|Game|Convex|Backend)\./, '')

/** The chips naming the axioms a proof rests on. */
const axiomLine = (declaration) => {
    if (declaration.axioms.length === 0) {
        return '<p class="rests">Rests on no axioms at all: the kernel reduces this one outright.</p>'
    }
    const clean = isKernelChecked(declaration)
    const chips = declaration.axioms
        .map((name) => `<span class="axiom${clean ? '' : ' warn'}">${escapeHtml(name)}</span>`)
        .join('')
    const label = clean
        ? 'Kernel-checked, resting only on'
        : 'Rests on an axiom outside the classical three:'
    return `<p class="rests${clean ? '' : ' warn'}">${label} ${chips}</p>`
}

/** Whether a pretty-printed type is worth showing: `Type` tells the reader nothing. */
const informative = (signature) => !/^(Type|Prop|Sort)( |$)/.test(signature)

const fileName = (path) => path.split('/').pop()

/** One declaration card. */
const card = (declaration, module, resolve) => {
    const isTheorem = declaration.kind === 'theorem'
    const shown = isTheorem ? statementOf(declaration) : declaration.signature
    const id = declarationId(declaration.name)
    const signature =
        isTheorem || informative(shown)
            ? `<pre class="sig"><code>${highlightLean(shown, module.name, resolve)}</code></pre>`
            : ''
    const doc = declaration.doc
        ? `<div class="blurb">${markdown(declaration.doc.trim(), (value) => resolve(value, module.name))}</div>`
        : ''
    const elaborated = isTheorem
        ? `<pre class="plain">${escapeHtml(declaration.signature)}</pre>`
        : ''
    const lines =
        declaration.startLine === declaration.endLine
            ? `${declaration.startLine}`
            : `${declaration.startLine}–${declaration.endLine}`
    const listing = isTheorem ? proofOf(declaration) : bodyOf(declaration)
    return `<article class="decl${isTheorem ? ' is-theorem' : ''}" id="${id}">
<div class="decl-head"><h4><a href="#${id}" title="${attribute(declaration.name)}">${escapeHtml(displayName(declaration.name))}</a></h4><span class="kind">${escapeHtml(declaration.kind)}</span><span class="at">${escapeHtml(fileName(module.file))} ${lines}</span></div>
${signature}
${doc}
${isTheorem ? axiomLine(declaration) : ''}
<details><summary>${isTheorem ? 'Proof, and the statement as the kernel sees it' : 'Source'}</summary>
<pre class="code"><code>${highlightLean(listing.trim(), module.name, resolve)}</code></pre>
${elaborated}
</details>
</article>`
}

/** A `/-! -/` block rendered inline between cards. */
const proseBlock = (block, module, resolve) =>
    `<div class="prose">${markdown(block.text.trim(), (value) => resolve(value, module.name))}</div>`

/** Merges prose blocks and declarations back into source order. */
const stream = (blocks, declarations, module, resolve) =>
    [
        ...blocks.map((block) => ({
            line: block.startLine,
            html: proseBlock(block, module, resolve),
        })),
        ...declarations.map((declaration) => ({
            line: declaration.startLine,
            html: card(declaration, module, resolve),
        })),
    ]
        .sort((left, right) => left.line - right.line)
        .map((entry) => entry.html)
        .join('\n')

/** Splits the module's prose into the opener and the blocks that head a later section. */
const splitProse = (module) => {
    const first = module.decls[0]?.startLine ?? Number.MAX_SAFE_INTEGER
    const opener = module.prose.filter((block) => block.startLine < first)
    const inner = module.prose.filter((block) => block.startLine >= first)
    const forTheorems = inner.filter((block) => {
        const next = module.decls.find((declaration) => declaration.startLine > block.startLine)
        return next?.kind === 'theorem'
    })
    return { opener, forTheorems, forDefinitions: inner.filter((b) => !forTheorems.includes(b)) }
}

const group = (title, count, noun, body) =>
    `<section class="group" data-total="${count} ${noun}"><div class="band"><h3>${title}</h3><span>${count} ${noun}</span></div>
${body}</section>`

/** One module chapter. */
const chapter = (module, index, resolve) => {
    const { opener, forDefinitions, forTheorems } = splitProse(module)
    const openerHtml = opener
        .map((block) => markdown(block.text.trim(), (value) => resolve(value, module.name)))
        .join('\n')
    const builds = module.imports
        .filter((name) => name.startsWith('Mythroads'))
        .map(
            (name) =>
                `<a href="#m-${escapeHtml(name.replaceAll('.', '-'))}">${escapeHtml(name.replace(/^Mythroads\./, ''))}</a>`,
        )
        .join(', ')
    const definitions =
        module.definitions.length > 0
            ? group(
                  'Definitions',
                  module.definitions.length,
                  module.definitions.length === 1 ? 'declaration' : 'declarations',
                  stream(forDefinitions, module.definitions, module, resolve),
              )
            : ''
    const theorems =
        module.theorems.length > 0
            ? group(
                  'What this module proves',
                  module.theorems.length,
                  module.theorems.length === 1 ? 'theorem' : 'theorems',
                  stream(forTheorems, module.theorems, module, resolve),
              )
            : ''
    const number = String(index).padStart(2, '0')
    return `<section class="chapter" id="${module.id}" data-s="${attribute(module.name.toLowerCase())}">
<div class="plate"><p class="num">${number}</p><div>
<h2>${escapeHtml(module.short)}</h2>
<p class="where">${escapeHtml(module.file)}, ${module.lines} lines</p>
${builds ? `<p class="builds">Builds on ${builds}</p>` : ''}
</div></div>
${openerHtml ? `<div class="prose">${openerHtml}</div>` : ''}
${definitions}
${theorems}
</section>`
}

const clientScript = `
const baseTitle = document.title
const find = document.getElementById('find')
const nothing = document.getElementById('nothing')
const chapters = Array.from(document.querySelectorAll('.chapter'))
const index = new WeakMap()
const tocLinks = new Map(
  Array.from(document.querySelectorAll('.tocwrap a')).map((link) => [link.dataset.chapter, link]),
)
const apply = (raw) => {
  const query = raw.trim().toLowerCase()
  let shown = 0
  const text = (decl) => {
    let cached = index.get(decl)
    if (cached === undefined) {
      cached = decl.textContent.toLowerCase().replace(/\\s+/g, ' ')
      index.set(decl, cached)
    }
    return cached
  }
  for (const chapter of chapters) {
    let visible = 0
    for (const group of chapter.querySelectorAll('.group')) {
      let inGroup = 0
      for (const decl of group.querySelectorAll('.decl')) {
        const match = query === '' || text(decl).includes(query)
        decl.hidden = !match
        if (match) inGroup += 1
      }
      group.hidden = inGroup === 0
      const tally = group.querySelector('.band span')
      tally.textContent =
        query === '' ? group.dataset.total : \`\${inGroup} of \${group.dataset.total}\`
      visible += inGroup
    }
    const named = query !== '' && chapter.dataset.s.includes(query)
    chapter.hidden = query !== '' && visible === 0 && !named
    for (const prose of chapter.querySelectorAll('.prose')) prose.hidden = query !== ''
    const link = tocLinks.get(chapter.id)
    if (link) link.hidden = chapter.hidden
    shown += visible
  }
  for (const part of document.querySelectorAll('.toc-part')) {
    const links = Array.from(part.querySelectorAll('a'))
    part.hidden = links.length > 0 && links.every((link) => link.hidden)
  }
  nothing.hidden = query === '' || shown > 0
  document.title = query === '' ? baseTitle : \`\${shown} matching declarations\`
}
find.addEventListener('input', (event) => apply(event.target.value))
document.addEventListener('keydown', (event) => {
  if (event.key === '/' && document.activeElement !== find) {
    event.preventDefault()
    find.focus()
  }
  if (event.key === 'Escape' && document.activeElement === find) {
    find.value = ''
    apply('')
  }
})
const toggle = document.getElementById('theme')
const store = (key, value) => {
  try {
    localStorage.setItem(key, value)
  } catch {
    // A browser with site data blocked simply forgets the choice.
  }
}
const read = (key) => {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}
const dark = () =>
  document.documentElement.dataset.theme === 'dark' ||
  (!document.documentElement.dataset.theme &&
    window.matchMedia('(prefers-color-scheme: dark)').matches)
const label = () => {
  toggle.textContent = dark() ? 'Light' : 'Dark'
}
const saved = read('mythroads-theme')
if (saved === 'dark' || saved === 'light') document.documentElement.dataset.theme = saved
label()
toggle.addEventListener('click', () => {
  const next = dark() ? 'light' : 'dark'
  document.documentElement.dataset.theme = next
  store('mythroads-theme', next)
  label()
})
`

/** Renders the whole page. */
export const renderPage = (model) => {
    const { parts, counts, resolve, toolchain } = model
    const step = model.modules
        .find((module) => module.name === 'Mythroads.Engine.Step')
        ?.decls.find((declaration) => declaration.name === 'Mythroads.Engine.step')
    const heroSource = step ? bodyOf(step) : 'def step (s : State) (env : Envelope) : Outcome'
    let index = 0
    const chapters = parts
        .map((part) =>
            part.modules
                .map((module) => {
                    index += 1
                    return chapter(module, index, resolve)
                })
                .join('\n'),
        )
        .join('\n')
    const toc = parts
        .map(
            (part) =>
                `<div class="toc-part"><p>${escapeHtml(part.title)}</p><ul>${part.modules
                    .map(
                        (module) =>
                            `<li><a href="#${module.id}" data-chapter="${module.id}">${escapeHtml(module.short)}</a></li>`,
                    )
                    .join('')}</ul></div>`,
        )
        .join('')
    const route = parts
        .map(
            (part) =>
                `<li><div><a href="#${part.modules[0]?.id ?? 'top'}">${escapeHtml(part.title)}</a><p>${escapeHtml(part.blurb)} ${part.modules.length} modules.</p></div></li>`,
        )
        .join('')
    return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>The Mythroads engine, in Lean</title>
<meta name="description" content="Generated from the Lean sources under proofs/: every declaration of the Mythroads game definition, its documentation, its source and what is proved about it.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=Literata:opsz,wght@7..72,400;7..72,600&display=swap">
<style>${style}</style>
</head>
<body>
<a class="skip" href="#reading">Skip to the reading order</a>
<div class="shell">
<aside class="spine">
<a class="mark" href="#top">Myth<span>roads</span></a>
<p class="spine-note">The game, as Lean defines it. Generated from the sources; never edited.</p>
<div class="find"><input id="find" type="search" placeholder="Search  /" aria-label="Search declarations"></div>
<div class="tocwrap">${toc}</div>
<div class="spine-foot"><span>Lean ${escapeHtml(toolchain)}</span><button type="button" id="theme" class="ghost">Dark</button></div>
</aside>
<main>
<header class="hero" id="top">
<p class="kicker">Mythroads is written down in Lean before it is a backend. This page is that writing, rendered by the compiler that checks it.</p>
<h1>One room, one event, one function.</h1>
<pre class="hero-sig"><code>${highlightLean(heroSource, 'Mythroads.Engine.Step', resolve)}</code></pre>
<p class="lede">Everything the server may do to a game of Mythroads happens inside <code>step</code>. It takes the room and one envelope — who is acting, for which hero, with what payload and what entropy — and returns either a refusal or the new room together with the writes Convex owes it. Three gates stand in front of the dispatch: does the actor hold the authority, is it that hero's turn, does the phase accept the event.</p>
<p class="lede">The chapters below are the modules themselves. Their own documentation is the prose; their declarations carry the signature the elaborator computed and the source exactly as it is on disk; and each chapter ends with what has been proved there, and which axioms those proofs rest on.</p>
<dl class="tally">
<div><dt>Modules</dt><dd>${counts.modules}</dd></div>
<div><dt>Declarations</dt><dd>${counts.declarations}</dd></div>
<div><dt>Theorems</dt><dd>${counts.theorems}</dd></div>
<div><dt>Lines of Lean</dt><dd>${counts.lines}</dd></div>
</dl>
</header>
<section class="guide" id="reading">
<h2>A reading order</h2>
<p>Lean loads a module only after everything it imports, so the order below is the import graph read from the bottom up. Nothing refers forward.</p>
<ol class="route">${route}</ol>
</section>
${chapters}
<p class="nothing" id="nothing" hidden>No declaration matches that. Try a shorter fragment, a Lean keyword, or a name such as <code>permitted</code>.</p>
<footer>
<p>Generated by <code>lake exe mythroads-docs</code> from <code>proofs/</code> on Lean ${escapeHtml(toolchain)}, and rewritten in place by <code>npm run docs:lean</code>. Editing this file by hand is pointless: <code>npm run check</code> compares it against the sources and fails when they disagree.</p>
</footer>
</main>
</div>
<script>${clientScript}</script>
</body>
</html>
`
}
