/** Generated from proofs/Mythroads/Game/Random.lean. Do not edit by hand. */
import type { Id } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'

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

export async function drawRoomRandom(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    bound: number,
): Promise<number> {
    const room = await ctx.db.get(roomId)
    if (!room) {
        throw new Error('Cannot draw randomness for a missing room.')
    }
    const draw = drawBounded(room.rngState ?? normalizeSeed(room._creationTime), bound)
    await ctx.db.patch(roomId, { rngState: draw.state, rngCounter: (room.rngCounter ?? 0) + 1 })
    return draw.value
}
