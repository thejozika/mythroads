import type { Doc, Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'

export function roomPhase(room: Doc<'rooms'>) {
    if (room.phase) return room.phase
    return room.remainingMoves > 0 ? 'moving' : 'awaitingRoll'
}

export async function advanceTurn(
    ctx: MutationCtx,
    room: Doc<'rooms'>,
    playerId: Id<'players'>,
    message: string,
) {
    const players = (
        await ctx.db
            .query('players')
            .withIndex('by_room', (q) => q.eq('roomId', room._id))
            .take(4)
    ).sort((a, b) => a.joinedAt - b.joinedAt)
    const currentIndex = players.findIndex((candidate) => candidate._id === playerId)
    const next = players[(currentIndex + 1) % players.length]
    await ctx.db.patch(room._id, {
        remainingMoves: 0,
        activePlayerId: next._id,
        round: currentIndex === players.length - 1 ? room.round + 1 : room.round,
        phase: 'awaitingRoll',
        activeEncounterId: undefined,
        shopKind: undefined,
        message,
    })
}
