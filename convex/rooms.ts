import { ConvexError, v } from 'convex/values'
import { getNode } from '../shared/board.system'
import { mutation, query } from './_generated/server'
import schema from './schema'

const roomCode = () => {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    return Array.from(
        { length: 4 },
        () => alphabet[Math.floor(Math.random() * alphabet.length)],
    ).join('')
}

export const create = mutation({
    args: {},
    returns: v.object({ code: v.string() }),
    handler: async (ctx) => {
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
        })
        return { code }
    },
})

export const byCode = query({
    args: { code: v.string() },
    returns: v.union(
        v.null(),
        v.object({ room: schema.doc('rooms'), players: v.array(schema.doc('players')) }),
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
        return { room, players: players.sort((a, b) => a.joinedAt - b.joinedAt) }
    },
})

export const join = mutation({
    args: { code: v.string(), name: v.string(), color: v.string() },
    returns: v.object({ playerId: v.id('players') }),
    handler: async (ctx, args) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (q) => q.eq('code', args.code.toUpperCase()))
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
            name: args.name.trim().slice(0, 16),
            color: args.color,
            position: 0,
            gold: 0,
            hp: 10,
            maxHp: 10,
            attack: 2,
            dice: [4, 6],
            joinedAt: Date.now(),
        })
        return { playerId }
    },
})

export const start = mutation({
    args: { roomId: v.id('rooms') },
    returns: v.null(),
    handler: async (ctx, { roomId }) => {
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
            message: `${first.name}, roll your movement dice.`,
        })
        return null
    },
})

export const roll = mutation({
    args: { roomId: v.id('rooms'), playerId: v.id('players') },
    returns: v.null(),
    handler: async (ctx, { roomId, playerId }) => {
        const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
        if (!room || !player || room.activePlayerId !== playerId || room.remainingMoves !== 0)
            throw new ConvexError('You cannot roll now.')
        const results = player.dice.map((sides) => 1 + Math.floor(Math.random() * sides))
        const total = results.reduce((sum, value) => sum + value, 0)
        // Backtracking is forbidden only within one roll, not between turns.
        await ctx.db.patch(playerId, { previousPosition: undefined })
        await ctx.db.patch(roomId, {
            lastRoll: results,
            remainingMoves: total,
            message: `${player.name} rolled ${total}.`,
        })
        return null
    },
})

export const step = mutation({
    args: { roomId: v.id('rooms'), playerId: v.id('players'), destination: v.number() },
    returns: v.null(),
    handler: async (ctx, { roomId, playerId, destination }) => {
        const [room, player] = await Promise.all([ctx.db.get(roomId), ctx.db.get(playerId)])
        if (!room || !player || room.activePlayerId !== playerId || room.remainingMoves <= 0)
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
            return null
        }

        const landed = getNode(destination)
        let message = `${player.name} reached ${landed.label}.`
        if (landed.kind === 'combat') {
            const power = player.attack + 1 + Math.floor(Math.random() * 6)
            if (power >= 6) {
                await ctx.db.patch(playerId, { gold: player.gold + 3 })
                message = `${player.name} defeated the ${landed.label} and won 3 gold!`
            } else {
                await ctx.db.patch(playerId, { hp: Math.max(1, player.hp - 2) })
                message = `${player.name} escaped the ${landed.label}, losing 2 health.`
            }
        } else if (landed.kind === 'event') {
            const gift = Math.random() >= 0.35
            const gold = gift ? player.gold + 2 : Math.max(0, player.gold - 1)
            await ctx.db.patch(playerId, { gold })
            message = gift
                ? `${player.name} found 2 gold at ${landed.label}.`
                : `${player.name} paid 1 gold at ${landed.label}.`
        }

        const players = (
            await ctx.db
                .query('players')
                .withIndex('by_room', (q) => q.eq('roomId', roomId))
                .take(4)
        ).sort((a, b) => a.joinedAt - b.joinedAt)
        const currentIndex = players.findIndex((candidate) => candidate._id === playerId)
        const next = players[(currentIndex + 1) % players.length]
        await ctx.db.patch(roomId, {
            remainingMoves: 0,
            activePlayerId: next._id,
            round: currentIndex === players.length - 1 ? room.round + 1 : room.round,
            message,
        })
        return null
    },
})
