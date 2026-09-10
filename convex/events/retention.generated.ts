/** Generated from proofs/Mythroads/Backend/Retention.lean. Do not edit by hand. */
import type { MutationCtx } from '../_generated/server'

export const GAME_EVENT_RETENTION_DAYS = 90
export const GAME_EVENT_RETENTION_BATCH_SIZE = 100

export async function deleteExpiredGameEventBatch(
    ctx: MutationCtx,
    cutoff: number,
): Promise<{ deleted: number; complete: boolean }> {
    const expired = await ctx.db
        .query('gameEvents')
        .withIndex('by_createdAt', (query) => query.lt('createdAt', cutoff))
        .take(100)
    for (const event of expired) {
        await ctx.db.delete(event._id)
    }
    return { deleted: expired.length, complete: expired.length < 100 }
}
