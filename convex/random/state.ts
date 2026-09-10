import type { Id } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'
import { drawBounded, normalizeSeed } from '../generated/random.generated'

export async function drawRoomRandom(ctx: MutationCtx, roomId: Id<'rooms'>, bound: number) {
    const room = await ctx.db.get(roomId)
    if (!room) throw new Error('Cannot draw randomness for a missing room.')
    const draw = drawBounded(room.rngState ?? normalizeSeed(room._creationTime), bound)
    await ctx.db.patch(roomId, {
        rngState: draw.state,
        rngCounter: (room.rngCounter ?? 0) + 1,
    })
    return draw.value
}
