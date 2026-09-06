import { defineSchema, defineTable } from 'convex/server'
import { v } from 'convex/values'

export default defineSchema({
    rooms: defineTable({
        code: v.string(),
        status: v.union(v.literal('lobby'), v.literal('playing'), v.literal('finished')),
        activePlayerId: v.optional(v.id('players')),
        remainingMoves: v.number(),
        lastRoll: v.optional(v.array(v.number())),
        message: v.string(),
        round: v.number(),
    }).index('by_code', ['code']),
    players: defineTable({
        roomId: v.id('rooms'),
        name: v.string(),
        color: v.string(),
        position: v.number(),
        previousPosition: v.optional(v.number()),
        gold: v.number(),
        hp: v.number(),
        maxHp: v.number(),
        attack: v.number(),
        dice: v.array(v.number()),
        joinedAt: v.number(),
    }).index('by_room', ['roomId']),
})
