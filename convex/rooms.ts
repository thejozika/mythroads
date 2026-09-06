import { ConvexError, v } from 'convex/values'
import { getNode, isShopKind } from '../shared/board.system'
import { outcomesFor, pickEncounter } from '../shared/encounter.system'
import type { Id } from './_generated/dataModel'
import { type MutationCtx, query } from './_generated/server'
import { advanceTurn, roomPhase } from './gameHelpers'
import schema from './schema'

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
        const camera = await ctx.db
            .query('roomCameras')
            .withIndex('by_roomId', (query) => query.eq('roomId', room._id))
            .unique()
        return { room, players: players.sort((a, b) => a.joinedAt - b.joinedAt), encounter, camera }
    },
})

export async function joinRoom(
    ctx: MutationCtx,
    code: string,
    data: { name: string; color: string },
) {
    const room = await ctx.db
        .query('rooms')
        .withIndex('by_code', (q) => q.eq('code', code.toUpperCase()))
        .unique()
    if (!room) throw new ConvexError('That room does not exist.')
    if (room.status !== 'lobby') throw new ConvexError('That adventure has already started.')
    const players = await ctx.db
        .query('players')
        .withIndex('by_room', (q) => q.eq('roomId', room._id))
        .take(4)
    if (players.length >= 4) throw new ConvexError('That room is full.')
    const playerId = await ctx.db.insert('players', {
        roomId: room._id,
        name: data.name.trim().slice(0, 16),
        color: data.color,
        position: 0,
        gold: 10,
        hp: 10,
        maxHp: 10,
        attack: 2,
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
    // Backtracking is forbidden only within one roll, not between turns.
    await ctx.db.patch(playerId, { previousPosition: undefined })
    await ctx.db.patch(roomId, {
        lastRoll: results,
        remainingMoves: total,
        phase: 'moving',
        message: `${player.name} rolled ${total}.`,
    })
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
    const origin = getNode(player.position)
    if (
        !origin.neighbors.includes(destination) ||
        (destination === player.previousPosition && origin.neighbors.length > 1)
    )
        throw new ConvexError('That road is not available.')
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
    if (landed.kind === 'combat' || landed.kind === 'event') {
        const outcome = pickEncounter(landed.kind, Math.random())
        const wheelIndex = outcomesFor(landed.kind).findIndex(
            (candidate) => candidate.id === outcome.id,
        )
        const encounterId = await ctx.db.insert('encounters', {
            roomId,
            playerId,
            spaceId: destination,
            kind: landed.kind,
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
            message: `${player.name} spins the ${landed.kind} wheel!`,
        })
        return
    }
    await advanceTurn(ctx, room, playerId, `${player.name} returned safely to camp.`)
}
