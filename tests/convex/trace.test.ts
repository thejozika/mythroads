import { describe, expect, test } from 'vitest'
import fixture from './fixtures/scenario-trace.json'
import { digest, materialize, playThrough, type TraceStep } from './playthrough.helper'
import { createScenario, type Scenario } from './scenario.helper'

/**
 * One long deterministic playthrough, recorded command by command. Regenerate the
 * fixture with `UPDATE_SCENARIO_TRACE=1 npm run test:convex -- trace` after a
 * deliberate rule change, and review the diff: every line is observed behaviour.
 */
const TRACE_SEED = 31415926
const TRACE_PLAYERS = ['Ava', 'Bo', 'Cy']
const LIMITS = { steps: 220, rounds: 8 }
const FIXTURE_PATH = 'tests/convex/fixtures/scenario-trace.json'

async function traceScenario(): Promise<Scenario> {
    return await createScenario({ seed: TRACE_SEED, players: TRACE_PLAYERS })
}

function updateRequested(): boolean {
    const runtime = globalThis as { process?: { env?: Record<string, string | undefined> } }
    return runtime.process?.env?.UPDATE_SCENARIO_TRACE === '1'
}

describe('recorded playthrough', () => {
    test('the fixture still describes what the backend does', async () => {
        const scenario = await traceScenario()
        if (updateRequested()) {
            const recorded = await playThrough(scenario, LIMITS)
            const fs = await import('node:fs')
            fs.writeFileSync(FIXTURE_PATH, `${JSON.stringify(recorded, null, 4)}\n`)
            expect(recorded.length).toBeGreaterThan(50)
            return
        }

        const steps = fixture as TraceStep[]
        expect(steps.length).toBeGreaterThan(50)
        for (const [index, step] of steps.entries()) {
            const event = await materialize(scenario, step.event)
            if (event.type === 'encounter.resolve') await scenario.ripenEncounter()
            const result = await scenario.dispatch(step.actor, event)
            expect(`${index}:${result.kind}`).toBe(`${index}:${step.resultKind}`)
            expect(`${index}:${await digest(scenario)}`).toBe(`${index}:${step.stateDigest}`)
        }
    })

    test('the recorded run exercises every persistent gameplay event', async () => {
        const steps = fixture as TraceStep[]
        const types = new Set(steps.map((step) => (step.event as { type: string }).type))
        expect([...types].sort()).toEqual([
            'camera.move',
            'camera.toggle',
            'camera.zoom',
            'combat.attack',
            'combat.guard',
            'encounter.resolve',
            'inventory.equip',
            'movement.cancel',
            'movement.roll',
            'movement.select',
            'movement.step',
            'shop.buy',
            'shop.leave',
        ])
    })

    test('replaying the same seed twice produces the same trace', async () => {
        const first = await playThrough(await traceScenario(), { steps: 40, rounds: 8 })
        const second = await playThrough(await traceScenario(), { steps: 40, rounds: 8 })
        expect(first.map((step) => step.stateDigest)).toEqual(
            second.map((step) => step.stateDigest),
        )
    })
})
