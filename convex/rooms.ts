import { ConvexError, v } from 'convex/values'
import { availableSteps, getNode, isShopKind } from '../shared/board.system'
import { outcomesFor, pickEncounter } from '../shared/encounter.system'
import type { Id } from './_generated/dataModel'
import { type MutationCtx, query } from './_generated/server'
import { advanceTurn, roomPhase } from './gameHelpers'
import schema from './schema'
import { startCombat } from './combat'

const roomCode = () => {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    return Array.from(
        { length: 4 },
        () => alphabet[Math.floor(Math.random() * alphabet.length)],
    ).join('')
}

export async function createRoom(ctx: MutationCtx) {
    let code = roomCode()
    while (
        await ctx.db
            .query('rooms')
            .withIndex('by_code', (q) => q.eq('code', code))
            .unique()
    )
        code = roomCode()
    await ctx.db.insert('rooms', {
        code,
        status: 'lobby',
        remainingMoves: 0,
        message: 'Scan the code to join the adventure.',
        round: 1,
        phase: 'awaitingRoll',
    })
    return code
}

export const byCode = query({
    args: { code: v.string() },
    returns: v.union(
        v.null(),
        v.object({
            room: schema.doc('rooms'),
            players: v.array(schema.doc('players')),
            encounter: v.union(v.null(), schema.doc('encounters')),
            combat: v.union(v.null(), schema.doc('combats')),
            selection: v.union(v.null(), schema.doc('roomSelections')),
            camera: v.union(v.null(), schema.doc('roomCameras')),
        }),
    ),
    handler: async (ctx, { code }) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (q) => q.eq('code', code.toUpperCase()))
            .unique()
        if (!room) return null
        const players = await ctx.db
            .query('players')
            .withIndex('by_room', (q) => q.eq('roomId', room._id))
            .take(4)
        const encounter = room.activeEncounterId ? await ctx.db.get(room.activeEncounterId) : null
        const combat = room.activeCombatId ? await ctx.db.get(room.activeCombatId) : null
        const selection = await ctx.db
            .query('roomSelections')
            .withIndex('by_roomId', (query) => query.eq('roomId', room._id))
            .first()
        const camera = await ctx.db
            .query('roomCameras')
            .withIndex('by_roomId', (query) => query.eq('roomId', room._id))
            .unique()
        return {
            room,
            players: players.sort((a, b) => a.joinedAt - b.joinedAt),
            encounter,
            combat,
            selection,
            camera,
        }
    },
})

export async function joinRoom(
    ctx: MutationCtx,
    code: string,
    data: { name: string; color: string },
) {
    const normalizedName = data.name.trim().slice(0, 16)
    if (!normalizedName) throw new ConvexError('Choose a hero name.')
    const room = await ctx.db
        .query('rooms')
        .withIndex('by_code', (q) => q.eq('code', code.toUpperCase()))
        .unique()
    if (!room) throw new ConvexError('That room does not exist.')
    const players = await ctx.db
        .query('players')
        .withIndex('by_room', (q) => q.eq('roomId', room._id))
        .take(4)
    const namedPlayer = players.find(
        (player) => player.name.toLocaleLowerCase() === normalizedName.toLocaleLowerCase(),
    )
    if (namedPlayer) {
        if (namedPlayer.color.toLocaleLowerCase() !== data.color.toLocaleLowerCase()) {
            throw new ConvexError('That hero exists. Select their original color to rejoin.')
        }
        return namedPlayer._id
    }
    if (room.status !== 'lobby') {
        throw new ConvexError(
            'That adventure has started. Rejoin with your existing name and color.',
        )
    }
    if (players.length >= 4) throw new ConvexError('That room is full.')
    const playerId = await ctx.db.insert('players', {
        roomId: room._id,
        name: normalizedName,
        color: data.color,
        position: 0,
        gold: 10,
        hp: 10,
        maxHp: 10,
        attack: 2,
        magic: 2,
        mp: 5,
        maxMp: 5,
        dice: [4, 6],
        joinedAt: Date.now(),
    })
    return playerId
}

export async function startRoom(ctx: MutationCtx, roomId: Id<'rooms'>) {
    const room = await ctx.db.get(roomId)
    if (room?.status !== 'lobby') return null
    const players = await ctx.db
        .query('players')
        .withIndex('by_room', (q) => q.eq('roomId', roomId))
        .take(4)
    if (!players.length) throw new ConvexError('At least one hero must join.')
    const first = players.sort((a, b) => a.joinedAt - b.joinedAt)[0]
    await ctx.db.patch(roomId, {
        status: 'playing',
        activePlayerId: first._id,
        phase: 'awaitingRoll',
        message: `${first.name}, roll your movement dice.`,
    })
}

export async function rollMovement(
    ctx: MutationCtx,
    { roomId, playerId }: { roomId: Id<'rooms'>; playerId: Id<'players'> },
) {
    const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
    if (
        !room ||
        !player ||
        room.activePlayerId !== playerId ||
        room.remainingMoves !== 0 ||
        roomPhase(room) !== 'awaitingRoll'
    )
        throw new ConvexError('You cannot roll now.')
    const results = player.dice.map((sides) => 1 + Math.floor(Math.random() * sides))
    const total = results.reduce((sum, value) => sum + value, 0)
    await clearSelection(ctx, roomId)
    await ctx.db.patch(playerId, { previousPosition: undefined })
    await ctx.db.patch(roomId, {
        lastRoll: results,
        remainingMoves: total,
        phase: 'moving',
        message: `${player.name} rolled ${total}.`,
    })
}

async function clearSelection(ctx: MutationCtx, roomId: Id<'rooms'>) {
    const selection = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    if (selection) await ctx.db.delete(selection._id)
}

export async function selectDestination(
    ctx: MutationCtx,
    {
        roomId,
        playerId,
        destination,
    }: { roomId: Id<'rooms'>; playerId: Id<'players'>; destination: number },
) {
    const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
    if (
        !room ||
        !player ||
        room.activePlayerId !== playerId ||
        roomPhase(room) !== 'moving' ||
        !availableSteps(player.position, player.previousPosition).includes(destination)
    )
        throw new ConvexError('That destination cannot be selected.')
    const current = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const value = { roomId, playerId, destination, updatedAt: Date.now() }
    if (current) await ctx.db.replace(current._id, value)
    else await ctx.db.insert('roomSelections', value)
    await ctx.db.patch(roomId, {
        message: `Selected ${getNode(destination).label}. Press A to move.`,
    })
}

export async function cancelDestination(
    ctx: MutationCtx,
    { roomId, playerId }: { roomId: Id<'rooms'>; playerId: Id<'players'> },
) {
    const room = await ctx.db.get(roomId)
    if (!room || room.activePlayerId !== playerId || roomPhase(room) !== 'moving')
        throw new ConvexError('There is no movement selection to cancel.')
    await clearSelection(ctx, roomId)
    await ctx.db.patch(roomId, { message: 'Choose a reachable field.' })
}

export async function movePlayer(
    ctx: MutationCtx,
    {
        roomId,
        playerId,
        destination,
    }: {
        roomId: Id<'rooms'>
        playerId: Id<'players'>
        destination: number
    },
) {
    const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
    if (
        !room ||
        !player ||
        room.activePlayerId !== playerId ||
        room.remainingMoves <= 0 ||
        roomPhase(room) !== 'moving'
    )
        throw new ConvexError('You cannot move now.')
    const allowed = availableSteps(player.position, player.previousPosition)
    const selection = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    if (!allowed.includes(destination) || selection?.destination !== destination)
        throw new ConvexError('That road is not available.')
    await clearSelection(ctx, roomId)
    await ctx.db.patch(playerId, { previousPosition: player.position, position: destination })
    const remaining = room.remainingMoves - 1
    if (remaining > 0) {
        await ctx.db.patch(roomId, { remainingMoves: remaining })
        return
    }

    const landed = getNode(destination)
    if (isShopKind(landed.kind)) {
        await ctx.db.patch(roomId, {
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
        const outcome = pickEncounter('event', Math.random())
        const wheelIndex = outcomesFor('event').findIndex(
            (candidate) => candidate.id === outcome.id,
        )
        const encounterId = await ctx.db.insert('encounters', {
            roomId,
            playerId,
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
        return
    }
    await advanceTurn(ctx, room, playerId, `${player.name} returned safely to camp.`)
}
