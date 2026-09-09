import { readFileSync, writeFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '../..')
const target = resolve(root, 'convex/generated/game-api.generated.ts')
const result = spawnSync('lake', ['exe', 'mythroads-codegen'], {
    cwd: resolve(root, 'proofs'),
    encoding: 'utf8',
})

if (result.status !== 0) {
    process.stderr.write(result.stderr)
    process.exit(result.status ?? 1)
}

const formatted = spawnSync(
    resolve(root, 'node_modules/.bin/biome'),
    ['format', '--stdin-file-path', target],
    { encoding: 'utf8', input: result.stdout },
)
if (formatted.status !== 0) {
    process.stderr.write(formatted.stderr)
    process.exit(formatted.status ?? 1)
}
const generated = formatted.stdout

if (process.argv.includes('--write')) {
    writeFileSync(target, generated)
    process.stdout.write('Generated Convex endpoint definitions from Lean.\n')
} else if (readFileSync(target, 'utf8') !== generated) {
    process.stderr.write('Lean-generated Convex code is stale. Run npm run proofs:generate.\n')
    process.exit(1)
} else {
    process.stdout.write('Lean proofs and generated Convex code agree.\n')
}
