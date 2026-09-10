/** Generated from proofs/Mythroads/Game/Random.lean. Do not edit by hand. */

export function normalizeSeed(seed: number): number {
    const whole = Math.trunc(Math.abs(seed))
    return (whole % 2147483646) + 1
}

export function nextRandom(state: number): number {
    return (state * 48271) % 2147483647
}

export function drawBounded(state: number, bound: number): { value: number; state: number } {
    if (bound <= 0) {
        throw new RangeError('Random bounds must be positive.')
    }
    const next = nextRandom(state)
    return { value: next % bound, state: next }
}

export function chanceHits(favorable: number, possible: number, roll: number): boolean {
    if (possible <= 0 || favorable < 0 || favorable > possible || roll < 0 || roll >= possible) {
        throw new RangeError('Chance bounds must be non-negative and possible must be positive.')
    }
    return roll < favorable
}
