import { ConvexError } from 'convex/values'
import { canTraverse, getNode, previewRouteStep } from '../shared/board.system'
import type { Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'
import { roomPhase } from './gameHelpers'
import { drawBounded, normalizeSeed } from './generated/random.generated'
import { resolveLanding } from './landings'
import { createPlayer } from './players'

const roomCode = (state: number) => {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    let rngState = state
    const code = Array.from({ length: 4 }, () => {
        const draw = drawBounded(rngState, alphabet.length)
        rngState = draw.state
        return alphabet.at(draw.value) ?? alphabet[0]
    }).join('')
    return { code, state: rngState }
}

export async function createRoom(ctx: MutationCtx, hostAuthId?: string, seed = Date.now()) {
    let rngState = normalizeSeed(seed)
    let generated = roomCode(rngState)
    let code = generated.code
    rngState = generated.state
    let rngCounter = 4
    while (
        await ctx.db
            .query('rooms')
            .withIndex('by_code', (q) => q.eq('code', code))
            .unique()
    ) {
        generated = roomCode(rngState)
        code = generated.code
        rngState = generated.state
        rngCounter += 4
    }
    await ctx.db.insert('rooms', {
        code,
        ...(hostAuthId ? { hostAuthId } : {}),
        status: 'lobby',
        remainingMoves: 0,
        message: 'Scan the code to join the adventure.',
        round: 1,
        phase: 'awaitingRoll',
        rngState,
        rngCounter,
    })
    return code
}

export async function joinRoom(
    ctx: MutationCtx,
    code: string,
    data: { name: string; color: string },
    authId?: string,
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
    const ownedPlayer = authId ? players.find((player) => player.authId === authId) : undefined
    if (ownedPlayer) return ownedPlayer._id
    const namedPlayer = players.find(
        (player) => player.name.toLocaleLowerCase() === normalizedName.toLocaleLowerCase(),
    )
    if (namedPlayer) {
        if (namedPlayer.authId && namedPlayer.authId !== authId) {
            throw new ConvexError('That hero name belongs to another account.')
        }
        if (namedPlayer.color.toLocaleLowerCase() !== data.color.toLocaleLowerCase()) {
            throw new ConvexError('That hero exists. Select their original color to rejoin.')
        }
        if (authId && !namedPlayer.authId) await ctx.db.patch(namedPlayer._id, { authId })
        return namedPlayer._id
    }
    if (room.status !== 'lobby') {
        throw new ConvexError(
            'That adventure has started. Rejoin with your existing name and color.',
        )
    }
    if (players.length >= 4) throw new ConvexError('That room is full.')
    return await createPlayer(ctx, room._id, { name: normalizedName, color: data.color }, authId)
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
    let rngState = room.rngState ?? normalizeSeed(room._creationTime)
    const results = player.dice.map((sides) => {
        const draw = drawBounded(rngState, sides)
        rngState = draw.state
        return draw.value + 1
    })
    const total = results.reduce((sum, value) => sum + value, 0)
    await clearSelection(ctx, roomId)
    await ctx.db.patch(playerId, { previousPosition: undefined })
    await ctx.db.patch(roomId, {
        lastRoll: results,
        remainingMoves: total,
        phase: 'moving',
        rngState,
        rngCounter: (room.rngCounter ?? 0) + results.length,
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
    const current = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const currentPath = current?.path ?? []
    if (!current && destination !== player.position)
        throw new ConvexError('Start route planning from the hero.')
    const path = current
        ? previewRouteStep(player.position, currentPath, destination, room.remainingMoves)
        : []
    if (!path) throw new ConvexError('That road cannot be used from here.')
    const previewDestination = path.at(-1) ?? player.position
    const remaining = room.remainingMoves - path.length
    const value = {
        roomId,
        playerId,
        destination: previewDestination,
        path,
        updatedAt: Date.now(),
    }
    if (current) await ctx.db.replace(current._id, value)
    else await ctx.db.insert('roomSelections', value)
    await ctx.db.patch(roomId, {
        message: remaining
            ? `Planning through ${getNode(previewDestination).label}. ${remaining} movement left.`
            : `Route ends at ${getNode(previewDestination).label}. Press A to travel.`,
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
    const path = selection?.path ?? []
    const validRoute = path.reduce(
        (valid, step, index) =>
            valid && canTraverse(index ? path[index - 1] : player.position, step),
        true,
    )
    if (
        !selection ||
        selection.destination !== destination ||
        path.length !== room.remainingMoves ||
        !validRoute
    )
        throw new ConvexError('That route is not available.')
    await clearSelection(ctx, roomId)
    await ctx.db.patch(playerId, {
        previousPosition: path.at(-2) ?? player.position,
        position: destination,
    })
    await resolveLanding(ctx, room, player, destination)
}
