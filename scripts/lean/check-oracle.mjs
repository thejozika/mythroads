/**
 * Staleness check for the engine parity fixture.
 *
 * `tests/engine/fixtures/engine-oracle.json` records what the *Lean* `Mythroads.Engine.step`
 * does with a set of scenarios and a seeded fuzz; `tests/engine/engine-parity.test.ts` replays
 * the same envelopes through the compiled TypeScript engine and compares. That comparison only
 * means something while the fixture matches the rules as they are now, so this script
 * regenerates it into a temporary directory and fails if the two differ.
 *
 * A rule change therefore fails here first, with a clear instruction, instead of failing as a
 * parity mismatch that looks like a compiler bug.
 *
 * Default mode reports and exits non-zero; `--write` updates the fixture instead, which is what
 * `npm run proofs:oracle` and `npm run proofs:generate` do. The fixture is machine-written data
 * and is excluded from Biome in `biome.json`, so it is compared byte for byte.
 */
import { spawnSync } from 'node:child_process'
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'

const root = resolve(import.meta.dirname, '../..')
const proofs = join(root, 'proofs')
const write = process.argv.includes('--write')
const fixture = 'tests/engine/fixtures/engine-oracle.json'

/** Runs a command, forwarding its output, and aborts the process if it fails. */
const run = (command, args, options = {}) => {
    const result = spawnSync(command, args, { stdio: 'inherit', ...options })
    if (result.status !== 0) {
        process.stderr.write(`${command} ${args.join(' ')} failed.\n`)
        process.exit(result.status ?? 1)
    }
}

const staging = mkdtempSync(join(tmpdir(), 'mythroads-oracle-'))
try {
    run('lake', ['build', 'mythroads-oracle'], { cwd: proofs })
    run('lake', ['exe', 'mythroads-oracle', staging], { cwd: proofs })

    const target = join(root, fixture)
    const expected = readFileSync(join(staging, fixture), 'utf8')
    const actual = statSync(target, { throwIfNoEntry: false }) && readFileSync(target, 'utf8')

    if (actual === expected) {
        process.stdout.write('The engine parity oracle matches the Lean engine.\n')
    } else if (write) {
        mkdirSync(dirname(target), { recursive: true })
        cpSync(join(staging, fixture), target)
        process.stdout.write(`Regenerated ${fixture} from the Lean engine.\n`)
    } else {
        process.stderr.write(`${fixture} is stale. Run npm run proofs:oracle.\n`)
        process.exit(1)
    }
} finally {
    rmSync(staging, { recursive: true, force: true })
}
