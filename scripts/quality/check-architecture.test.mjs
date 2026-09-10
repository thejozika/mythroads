import assert from 'node:assert/strict'
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { inspectRepository } from './check-architecture.mjs'

function fixture() {
    const root = mkdtempSync(join(tmpdir(), 'dicebound-architecture-'))
    for (const directory of ['src', 'convex', 'shared']) {
        mkdirSync(join(root, directory), { recursive: true })
    }
    return root
}

test('accepts a small typed module', () => {
    const root = fixture()
    writeFileSync(join(root, 'src', 'format.util.ts'), "export const format = () => 'ok'\n")
    assert.deepEqual(inspectRepository(root), [])
})

test('rejects an untyped frontend filename', () => {
    const root = fixture()
    writeFileSync(join(root, 'src', 'mystery.ts'), 'export const value = 1\n')
    assert.match(inspectRepository(root).join('\n'), /needs a taxonomy suffix/)
})

test('rejects an oversized source module', () => {
    const root = fixture()
    writeFileSync(join(root, 'src', 'large.util.ts'), 'const value = 1\n'.repeat(301))
    assert.match(inspectRepository(root).join('\n'), /exceeds the 300-line limit/)
})

test('exempts only the compiled Lean engine from the line limit', () => {
    const root = fixture()
    mkdirSync(join(root, 'shared', 'generated'), { recursive: true })
    const body = 'export const value = 1\n'.repeat(301)
    writeFileSync(join(root, 'shared', 'generated', 'engine.generated.ts'), body)
    writeFileSync(join(root, 'shared', 'generated', 'board.generated.ts'), body)
    const findings = inspectRepository(root).join('\n')
    assert.doesNotMatch(findings, /engine\.generated\.ts/)
    assert.match(findings, /board\.generated\.ts: 302 lines exceeds the 300-line limit/)
})

test('rejects an overcrowded code directory', () => {
    const root = fixture()
    for (let index = 0; index < 13; index += 1) {
        writeFileSync(join(root, 'shared', `rule-${index}.system.ts`), 'export const value = 1\n')
    }
    assert.match(inspectRepository(root).join('\n'), /exceeds the 12-file folder limit/)
})

test('keeps Convex out of Three.js scene modules', () => {
    const root = fixture()
    writeFileSync(
        join(root, 'src', 'Board.scene.tsx'),
        "import { useQuery } from 'convex/react'\nexport function BoardScene() { return null }\n",
    )
    assert.match(inspectRepository(root).join('\n'), /scenes cannot access Convex/)
})

test('keeps deterministic gameplay systems runtime-independent', () => {
    const root = fixture()
    writeFileSync(
        join(root, 'shared', 'movement.system.ts'),
        "import { Vector3 } from 'three'\nexport const movement = new Vector3()\n",
    )
    assert.match(inspectRepository(root).join('\n'), /runtime-independent/)
})
