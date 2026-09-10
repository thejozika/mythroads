/**
 * Builds the HTML reader for the Lean sources.
 *
 * The reader used to scrape `proofs/Mythroads/**` with regular expressions, which meant it guessed
 * at declaration kinds, could not show a signature, and silently dropped anything whose formatting
 * it did not anticipate. It now consumes the elaborator's own answer: `lake exe mythroads-docs`
 * imports the compiled modules and prints every authored declaration with its kind, docstring,
 * signature, line range, exact source, and — for theorems — the axioms the proof depends on.
 *
 *   node scripts/lean/build-definition-reader.mjs          rewrites both copies of the page
 *   node scripts/lean/build-definition-reader.mjs --check   fails when they are out of date
 *
 * Two copies are written because they serve two readers: `documents/engineering/` is where the
 * engineering notes link to it, and `public/` is what the application serves at `/lean`.
 */

import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { buildModel } from './reader/model.mjs'
import { renderPage } from './reader/page.mjs'

const root = resolve(import.meta.dirname, '../..')
const proofs = join(root, 'proofs')

/** The two library roots; everything below `Mythroads` in their import closure is documented. */
const roots = ['Mythroads', 'Mythroads.Engine']

const targets = [
    join(root, 'documents/engineering/lean-definitions.html'),
    join(root, 'public/lean-definitions.html'),
]

/**
 * Runs a Lake command inside `proofs/`.
 *
 * `lake` on PATH is an elan shim that reads `proofs/lean-toolchain`, so the working directory is
 * load-bearing; an inherited `ELAN_TOOLCHAIN` would override it, so it is dropped.
 */
const lake = (args, capture) => {
    const { ELAN_TOOLCHAIN, ...environment } = process.env
    const command = process.env.LAKE ?? 'lake'
    const result = spawnSync(command, args, {
        cwd: proofs,
        env: environment,
        maxBuffer: 64 * 1024 * 1024,
        stdio: capture ? ['ignore', 'pipe', 'inherit'] : 'inherit',
    })
    if (result.error) {
        process.stderr.write(`Could not run ${command}: ${result.error.message}\n`)
        process.exit(1)
    }
    if (result.status !== 0) {
        process.stderr.write(`lake ${args.join(' ')} failed.\n`)
        process.exit(result.status ?? 1)
    }
    return capture ? result.stdout.toString() : ''
}

// `+Module` builds the module facet rather than the library glob, so an unfinished file elsewhere
// in `proofs/` cannot block the documentation of the modules these roots actually reach.
lake(['build', ...roots.map((name) => `+${name}`), 'mythroads-docs'], false)
const exported = JSON.parse(lake(['exe', 'mythroads-docs', '.', ...roots], true))

const model = buildModel(exported)
const html = renderPage(model)
const { modules, declarations, theorems } = model.counts

if (process.argv.includes('--check')) {
    const stale = targets.filter(
        (target) => !existsSync(target) || readFileSync(target, 'utf8') !== html,
    )
    if (stale.length > 0) {
        for (const target of stale) process.stderr.write(`${target} is out of date.\n`)
        process.stderr.write('Run npm run docs:lean.\n')
        process.exit(1)
    }
    process.stdout.write(
        `Lean reader matches the sources: ${declarations} declarations in ${modules} modules.\n`,
    )
} else {
    for (const target of targets) {
        mkdirSync(dirname(target), { recursive: true })
        writeFileSync(target, html)
    }
    process.stdout.write(
        `Rendered ${declarations} declarations and ${theorems} theorems from ${modules} Lean modules.\n`,
    )
}
