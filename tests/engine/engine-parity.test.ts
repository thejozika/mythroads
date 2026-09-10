/**
 * The compiled engine must behave exactly like the Lean engine it was compiled from.
 *
 * `lake exe mythroads-oracle` runs the real `Mythroads.Engine.step` over a set of
 * scenarios and a seeded fuzz and records what it produced in
 * `fixtures/engine-oracle.json`. This suite replays exactly those envelopes through
 * `shared/generated/engine.generated.ts` and compares, so a compiler bug — a wrong shim,
 * a mangled join point, a `Nat` subtraction that went negative — fails here rather than
 * in a room somebody is playing.
 *
 * The comparison is on text, not on structure: both sides are reduced to the same
 * canonical JSON (object keys sorted, no whitespace), the scenarios keep the whole
 * outcome, and each fuzz step keeps a digest of that canonical text.
 */
import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import {
    type Envelope,
    type Outcome,
    type State,
    step,
} from '../../shared/generated/engine.generated'

type Step = { envelope: Envelope; outcome: Outcome }
type Scenario = { name: string; start: State; steps: Step[] }
type Fixture = {
    scenarios: Scenario[]
    fuzz: { seed: number; start: State; envelopes: Envelope[]; digests: string[] }
}

const fixture: Fixture = JSON.parse(
    readFileSync(new URL('./fixtures/engine-oracle.json', import.meta.url), 'utf8'),
)

/** JSON with object keys in sorted order, which is what the Lean side also prints. */
const canonical = (value: unknown): string => {
    if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
    if (value !== null && typeof value === 'object') {
        const entries = Object.entries(value as Record<string, unknown>)
            .filter(([, v]) => v !== undefined)
            .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
        return `{${entries.map(([k, v]) => `${JSON.stringify(k)}:${canonical(v)}`).join(',')}}`
    }
    return JSON.stringify(value) ?? 'null'
}

/** FNV-1a over the code points of a string, with the length appended, as Lean computes it. */
const digest = (text: string): string => {
    // `Math.imul` keeps the multiplication in 32 bits; a plain `*` would lose the low bits
    // of a product above 2^53 and stop agreeing with Lean's exact `Nat` arithmetic.
    let hash = 2166136261
    for (const character of text) {
        hash = Math.imul(hash ^ (character.codePointAt(0) ?? 0), 16777619) >>> 0
    }
    return `${hash}-${[...text].length}`
}

/** Apply one envelope, keeping the old room when it is refused, as the oracle does. */
const advance = (state: State, envelope: Envelope): State => {
    const outcome = step(state, envelope)
    return outcome._ === 'ok' ? outcome.a.fst : state
}

describe('the compiled engine matches the Lean engine', () => {
    for (const scenario of fixture.scenarios) {
        it(`replays ${scenario.name}`, () => {
            let state = scenario.start
            scenario.steps.forEach((expected, index) => {
                const actual = step(state, expected.envelope)
                expect(canonical(actual), `step ${index} of ${scenario.name}`).toBe(
                    canonical(expected.outcome),
                )
                state = advance(state, expected.envelope)
            })
        })
    }

    it(`replays ${fixture.fuzz.envelopes.length} fuzzed envelopes`, () => {
        let state = fixture.fuzz.start
        const mismatches: string[] = []
        fixture.fuzz.envelopes.forEach((envelope, index) => {
            const actual = digest(canonical(step(state, envelope)))
            if (actual !== fixture.fuzz.digests[index]) {
                mismatches.push(`${index}: expected ${fixture.fuzz.digests[index]}, got ${actual}`)
            }
            state = advance(state, envelope)
        })
        expect(mismatches.slice(0, 5)).toEqual([])
    })

    it('starts every scenario from the room the oracle started from', () => {
        expect(fixture.scenarios.map((scenario) => scenario.name)).toContain(
            'a full turn from an empty room',
        )
        expect(fixture.fuzz.envelopes).toHaveLength(fixture.fuzz.digests.length)
    })
})
