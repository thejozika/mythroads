import { getNode, isShopKind } from '../shared/board.system'
import { outcomesFor, pickEncounter } from '../shared/encounter.system'
import type { Doc, Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'
import { startCombat } from './combat'
import { advanceTurn } from './gameHelpers'

export async function resolveLanding(
    ctx: MutationCtx,
    room: Doc<'rooms'>,
    player: Doc<'players'>,
    destination: number,
) {
    const landed = getNode(destination)
    if (isShopKind(landed.kind)) {
        await ctx.db.patch(room._id, {
            remainingMoves: 0,
            phase: 'shopping',
            shopKind: landed.kind,
            message: `${player.name} entered the ${landed.label}.`,
        })
        return
    }
    if (landed.kind === 'combat') {
        await startCombat(ctx, room, player, destination)
        return
    }
    if (landed.kind === 'event') {
        await startEvent(ctx, room._id, player, destination)
        return
    }
    await advanceTurn(ctx, room, player._id, `${player.name} returned safely to camp.`)
}

async function startEvent(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    player: Doc<'players'>,
    destination: number,
) {
    const outcome = pickEncounter('event', Math.random())
    const wheelIndex = outcomesFor('event').findIndex((candidate) => candidate.id === outcome.id)
    const encounterId = await ctx.db.insert('encounters', {
        roomId,
        playerId: player._id,
        spaceId: destination,
        kind: 'event',
        outcomeId: outcome.id,
        title: outcome.title,
        description: outcome.description,
        goldDelta: outcome.goldDelta,
        hpDelta: outcome.hpDelta,
        wheelIndex,
        status: 'revealing',
        createdAt: Date.now(),
    })
    await ctx.db.patch(roomId, {
        remainingMoves: 0,
        phase: 'revealingEncounter',
        activeEncounterId: encounterId,
        message: `${player.name} spins the event wheel!`,
    })
}
