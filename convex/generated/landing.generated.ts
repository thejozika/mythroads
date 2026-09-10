/** Generated from proofs/Mythroads/Backend/Landing.lean. Do not edit by hand. */
import { getNode, isShopKind } from '../../shared/board.system'
import { encounterWeight, outcomesFor, pickEncounter } from '../../shared/encounter.system'
import type { Doc, Id } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'
import { startCombat } from '../combat'
import { advanceTurn } from '../gameHelpers'
import { drawRoomRandom } from '../random/state'

export async function resolveLanding(
    ctx: MutationCtx,
    room: Doc<'rooms'>,
    player: Doc<'players'>,
    destination: number,
): Promise<void> {
    const landed = getNode(destination)
    if (isShopKind(landed.kind)) {
        await ctx.db.patch(room._id, {
            remainingMoves: 0,
            phase: 'shopping',
            shopKind: landed.kind,
            message: player.name + ' entered the ' + (landed.label + '.'),
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
    if (landed.kind === 'castle') {
        await ctx.db.patch(player._id, { hp: player.maxHp })
        await advanceTurn(
            ctx,
            room,
            player._id,
            player.name + ' rested at Hearthkeep and recovered all health.',
        )
        return
    }
    await advanceTurn(ctx, room, player._id, player.name + ' completed the journey.')
}

async function startEvent(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    player: Doc<'players'>,
    destination: number,
): Promise<void> {
    const roll = await drawRoomRandom(ctx, roomId, encounterWeight('event'))
    const outcome = pickEncounter('event', roll)
    const wheelIndex = outcomesFor('event').findIndex((candidate) => candidate.id === outcome.id)
    const encounterId = await ctx.db.insert('encounters', {
        roomId: roomId,
        playerId: player._id,
        spaceId: destination,
        kind: 'event',
        outcomeId: outcome.id,
        title: outcome.title,
        description: outcome.description,
        goldDelta: outcome.goldDelta,
        hpDelta: outcome.hpDelta,
        wheelIndex: wheelIndex,
        status: 'revealing',
        createdAt: Date.now(),
    })
    await ctx.db.patch(roomId, {
        remainingMoves: 0,
        phase: 'revealingEncounter',
        activeEncounterId: encounterId,
        message: player.name + ' spins the event wheel!',
    })
}
