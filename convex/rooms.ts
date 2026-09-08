import { ConvexError, v } from 'convex/values'
import { getNode, reachableRoutes } from '../shared/board.system'
import type { Id } from './_generated/dataModel'
import { type MutationCtx, query } from './_generated/server'
import { roomPhase } from './gameHelpers'
import { resolveLanding } from './landings'
import { createPlayer } from './players'
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
    return await createPlayer(ctx, room._id, { name: normalizedName, color: data.color })
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
        message: `${player.name} rolled ${total}. Press Y to choose a destination.`,
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
    if (!room || !player || room.activePlayerId !== playerId || roomPhase(room) !== 'moving')
        throw new ConvexError('That destination cannot be selected.')
    const route = reachableRoutes(
        player.position,
        player.previousPosition,
        room.remainingMoves,
    ).find((candidate) => candidate.destination === destination)
    if (!route) throw new ConvexError('That field cannot be reached with this roll.')
    const current = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const value = { roomId, playerId, destination, path: route.path, updatedAt: Date.now() }
    if (current) await ctx.db.replace(current._id, value)
    else await ctx.db.insert('roomSelections', value)
    await ctx.db.patch(roomId, {
        message: `Targeting ${getNode(destination).label}. Press A to travel or B to cancel.`,
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
    await ctx.db.patch(roomId, { message: 'Press Y to choose a destination.' })
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
    const selection = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const route = reachableRoutes(
        player.position,
        player.previousPosition,
        room.remainingMoves,
    ).find((candidate) => candidate.destination === destination)
    if (!route || selection?.destination !== destination)
        throw new ConvexError('That route is not available.')
    await clearSelection(ctx, roomId)
    await ctx.db.patch(playerId, {
        previousPosition: route.path.at(-2) ?? player.position,
        position: destination,
    })
    await resolveLanding(ctx, room, player, destination)
}
