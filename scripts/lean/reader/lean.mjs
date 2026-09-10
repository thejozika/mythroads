/**
 * Lean syntax highlighting with working cross-references.
 *
 * The highlighter is a single-pass tokenizer: comments, strings, numbers, identifiers, and the
 * operator alphabet Lean actually uses. The point of it is not colour — it is the identifier case.
 * Every identifier is offered to the model's resolver, and when it names a documented declaration
 * the token becomes a link to that declaration's card. Reading `step` in `Engine.Replay` and
 * clicking through to its definition is the difference between a listing and a reader.
 */

import { escapeHtml } from './markdown.mjs'

const keywords = new Set([
    'abbrev',
    'attribute',
    'by',
    'case',
    'cases',
    'def',
    'deriving',
    'do',
    'else',
    'end',
    'example',
    'exact',
    'for',
    'forall',
    'fun',
    'have',
    'if',
    'import',
    'in',
    'inductive',
    'instance',
    'intro',
    'let',
    'match',
    'mutual',
    'namespace',
    'noncomputable',
    'obtain',
    'open',
    'partial',
    'private',
    'protected',
    'refine',
    'rename_i',
    'return',
    'rfl',
    'rw',
    'section',
    'simp',
    'simpa',
    'split',
    'structure',
    'termination_by',
    'theorem',
    'then',
    'this',
    'unfold',
    'unless',
    'variable',
    'where',
    'with',
])

const literals = new Set(['true', 'false', 'none', 'some', 'Prop', 'Type', 'Sort'])

const tokenPattern = new RegExp(
    [
        '/-[\\s\\S]*?-/',
        '--[^\\n]*',
        '"(?:\\\\.|[^"\\\\])*"',
        "'(?:\\\\.|[^'\\\\])'",
        '\\b\\d+\\b',
        '#[A-Za-z_]+',
        "\\.?[A-Za-z_][A-Za-z0-9_'!?]*(?:\\.[A-Za-z_][A-Za-z0-9_'!?]*)*",
        ':=|=>|<\\||\\|>|→|←|↔|∀|∃|∧|∨|¬|≠|≤|≥|×|⟨|⟩|·|∘|⊢',
    ].join('|'),
    'g',
)

/** Renders one identifier token, linking it when the resolver knows the name. */
const identifier = (token, context, resolve) => {
    const bare = token.startsWith('.') ? token.slice(1) : token
    const text = escapeHtml(token)
    if (keywords.has(bare)) return `<b class="k">${text}</b>`
    if (literals.has(bare)) return `<i class="l">${text}</i>`
    const target = resolve(bare, context)
    // An identifier that neither is a keyword nor resolves needs no markup: it is body colour.
    return target ? `<a class="r" href="#${target}">${text}</a>` : text
}

/**
 * Highlights a block of Lean source.
 *
 * `context` is the module the source came from, so an identifier resolves the way it would in that
 * module's namespace rather than globally.
 */
export const highlightLean = (source, context, resolve) => {
    let cursor = 0
    let out = ''
    for (const match of source.matchAll(tokenPattern)) {
        const token = match[0]
        out += escapeHtml(source.slice(cursor, match.index))
        cursor = match.index + token.length
        if (token.startsWith('/-') || token.startsWith('--')) {
            out += `<i class="c">${escapeHtml(token)}</i>`
        } else if (token.startsWith('"') || token.startsWith("'")) {
            out += `<i class="s">${escapeHtml(token)}</i>`
        } else if (/^\d/.test(token)) {
            out += `<i class="n">${escapeHtml(token)}</i>`
        } else if (/^[.A-Za-z_]/.test(token)) {
            out += identifier(token, context, resolve)
        } else if (token.startsWith('#')) {
            out += `<b class="k">${escapeHtml(token)}</b>`
        } else {
            out += `<i class="o">${escapeHtml(token)}</i>`
        }
    }
    return out + escapeHtml(source.slice(cursor))
}
