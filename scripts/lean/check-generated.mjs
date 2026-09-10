/**
 * Drift check for the Lean-authored TypeScript boundary.
 *
 * The Lean side owns the list of generated files (`proofs/Emit.lean`'s `outputs`), so this script
 * no longer restates it. It builds the two generator executables, runs them into one staging
 * directory, lets Biome canonicalize that tree (import order first, then formatting), and compares
 * the result with the repository tree.
 *
 * `mythroads-emit` prints the Convex boundary from Lean values; `mythroads-compile` compiles the
 * Lean engine itself, `Mythroads.Engine.step` and its whole reachable closure, into
 * `shared/generated/engine.generated.ts`. Both write into the same staging tree, so one comparison
 * covers everything Lean generates.
 *
 * Comparing whole trees rather than file-by-file also catches a case the previous per-executable
 * loop could not: a generated file left behind in the repository after its Lean source was
 * deleted.
 *
 * Default mode reports stale, missing, and extra files and exits non-zero. `--write` copies the
 * staged tree over the repository instead, which is what `npm run proofs:generate` does.
 */
import { spawnSync } from 'node:child_process'
import {
    cpSync,
    mkdirSync,
    mkdtempSync,
    readFileSync,
    readdirSync,
    rmSync,
    statSync,
} from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'

const root = resolve(import.meta.dirname, '../..')
const proofs = join(root, 'proofs')
const biome = join(root, 'node_modules/.bin/biome')
const write = process.argv.includes('--write')

/** Runs a command, forwarding its output, and aborts the process if it fails. */
const run = (command, args, options = {}) => {
    const result = spawnSync(command, args, { stdio: 'inherit', ...options })
    if (result.status !== 0) {
        process.stderr.write(`${command} ${args.join(' ')} failed.\n`)
        process.exit(result.status ?? 1)
    }
}

/** Every file below `directory`, as paths relative to it, sorted for deterministic reporting. */
const treeFiles = (directory, prefix = '') => {
    const entries = []
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
        const child = join(directory, entry.name)
        const name = prefix ? `${prefix}/${entry.name}` : entry.name
        if (entry.isDirectory()) entries.push(...treeFiles(child, name))
        else entries.push(name)
    }
    return entries.sort()
}

const staging = mkdtempSync(join(tmpdir(), 'mythroads-emit-'))
try {
    run('lake', ['build', 'mythroads-emit', 'mythroads-compile'], { cwd: proofs })
    run('lake', ['exe', 'mythroads-emit', staging], { cwd: proofs })
    run('lake', ['exe', 'mythroads-compile', staging], { cwd: proofs })
    run(biome, ['check', '--write', '--only=assist/source/organizeImports', staging], { cwd: root })
    run(biome, ['format', '--write', staging], { cwd: root })

    const generated = treeFiles(staging)
    const stale = []
    for (const file of generated) {
        const target = join(root, file)
        const expected = readFileSync(join(staging, file), 'utf8')
        const actual = statSync(target, { throwIfNoEntry: false }) && readFileSync(target, 'utf8')
        if (actual === expected) continue
        if (write) {
            mkdirSync(dirname(target), { recursive: true })
            cpSync(join(staging, file), target)
        } else stale.push(actual === undefined || actual === null ? `${file} (missing)` : file)
    }

    // A generated file whose Lean source disappeared would otherwise linger unnoticed.
    const owned = new Set(generated)
    const directories = [...new Set(generated.map((file) => dirname(file)))]
    const extra = [
        ...new Set(
            directories
                .flatMap((directory) => treeFiles(join(root, directory), directory))
                .filter((file) => file.endsWith('.generated.ts') && !owned.has(file)),
        ),
    ].sort()

    if (!write && (stale.length > 0 || extra.length > 0)) {
        for (const file of stale) process.stderr.write(`${file} is stale.\n`)
        for (const file of extra) process.stderr.write(`${file} has no Lean source.\n`)
        process.stderr.write('Run npm run proofs:generate.\n')
        process.exit(1)
    }
    if (write && extra.length > 0) {
        for (const file of extra) {
            process.stderr.write(`${file} has no Lean source; delete it.\n`)
        }
        process.exit(1)
    }

    process.stdout.write(
        write
            ? `Generated ${generated.length} Convex modules from Lean.\n`
            : 'Lean proofs and generated Convex modules agree.\n',
    )
} finally {
    rmSync(staging, { recursive: true, force: true })
}
