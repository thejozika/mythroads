/**
 * Axiom audit for the Lean proofs.
 *
 * `proofs/Axioms.lean` enumerates every theorem reachable from the `Mythroads` import root and
 * fails elaboration if any of them depends on an axiom outside {propext, Quot.sound,
 * Classical.choice} — a `sorry` left behind, or a `native_decide` proof the kernel never checked.
 * This script builds that closure and elaborates the file, so the audit runs as an ordinary
 * `npm run` step.
 *
 * The build target is the emitter rather than the whole library: the emitter's transitive imports
 * are exactly `Mythroads.lean`'s, which is the set the audit reasons about.
 */
import { spawnSync } from 'node:child_process'
import { join, resolve } from 'node:path'

const proofs = resolve(import.meta.dirname, '../../proofs')

for (const args of [
    ['build', 'mythroads-emit'],
    ['env', 'lean', join(proofs, 'Axioms.lean')],
]) {
    const result = spawnSync('lake', args, { cwd: proofs, stdio: 'inherit' })
    if (result.status !== 0) process.exit(result.status ?? 1)
}
