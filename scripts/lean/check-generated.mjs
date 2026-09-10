import { readFileSync, writeFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '../..')
const generatedModules = [
    { executable: 'mythroads-codegen', file: 'game-api.generated.ts' },
    { executable: 'mythroads-inventory-codegen', file: 'inventory.generated.ts' },
    { executable: 'mythroads-schema-codegen', file: 'schema.generated.ts' },
    { executable: 'mythroads-random-codegen', file: 'random.generated.ts' },
    { executable: 'mythroads-events-codegen', file: '../events/validators.generated.ts' },
    { executable: 'mythroads-router-codegen', file: '../events/router.generated.ts' },
    { executable: 'mythroads-policy-codegen', file: '../events/policy.generated.ts' },
    { executable: 'mythroads-authorization-codegen', file: '../auth/authorization.generated.ts' },
    { executable: 'mythroads-authority-codegen', file: '../events/authority.generated.ts' },
    { executable: 'mythroads-persistence-codegen', file: '../events/persistence.generated.ts' },
    { executable: 'mythroads-retention-codegen', file: '../events/retention.generated.ts' },
    { executable: 'mythroads-player-codegen', file: 'player.generated.ts' },
    { executable: 'mythroads-shop-codegen', file: 'shop.generated.ts' },
    { executable: 'mythroads-turn-codegen', file: 'turn.generated.ts' },
    { executable: 'mythroads-encounter-codegen', file: 'encounter.generated.ts' },
    { executable: 'mythroads-landing-codegen', file: 'landing.generated.ts' },
    { executable: 'mythroads-camera-codegen', file: 'camera.generated.ts' },
]

for (const module of generatedModules) {
    const target = resolve(root, 'convex/generated', module.file)
    const result = spawnSync('lake', ['exe', module.executable], {
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
    if (process.argv.includes('--write')) {
        writeFileSync(target, formatted.stdout)
    } else if (readFileSync(target, 'utf8') !== formatted.stdout) {
        process.stderr.write(`${module.file} is stale. Run npm run proofs:generate.\n`)
        process.exit(1)
    }
}

process.stdout.write(
    process.argv.includes('--write')
        ? 'Generated Convex modules from Lean.\n'
        : 'Lean proofs and generated Convex modules agree.\n',
)
