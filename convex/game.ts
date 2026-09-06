import { v } from 'convex/values'
import { mutation } from './_generated/server'
import { resolveEncounter } from './encounters'
import { createRoom, joinRoom, movePlayer, rollMovement, startRoom } from './rooms'
import { buyItem, equipItem, leaveShop } from './shops'

const eventValidator = v.union(
    v.object({ type: v.literal('room.create'), subjects: v.object({}), data: v.object({}) }),
    v.object({
        type: v.literal('player.join'),
        subjects: v.object({ code: v.string() }),
        data: v.object({ name: v.string(), color: v.string() }),
    }),
    v.object({
        type: v.literal('game.start'),
        subjects: v.object({ roomId: v.id('rooms') }),
        data: v.object({}),
    }),
    v.object({
        type: v.literal('movement.roll'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({}),
    }),
    v.object({
        type: v.literal('movement.step'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({ destination: v.number() }),
    }),
    v.object({
        type: v.literal('encounter.resolve'),
        subjects: v.object({
            roomId: v.id('rooms'),
            playerId: v.id('players'),
            encounterId: v.id('encounters'),
        }),
        data: v.object({}),
    }),
    v.object({
        type: v.literal('shop.buy'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({ itemId: v.string() }),
    }),
    v.object({
        type: v.literal('inventory.equip'),
        subjects: v.object({ playerId: v.id('players'), playerItemId: v.id('playerItems') }),
        data: v.object({
            slot: v.union(
                v.literal('weapon'),
                v.literal('helmet'),
                v.literal('body'),
                v.literal('gloves'),
                v.literal('boots'),
                v.literal('cape'),
                v.literal('amulet'),
                v.literal('ringLeft'),
                v.literal('ringRight'),
            ),
        }),
    }),
    v.object({
        type: v.literal('shop.leave'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({}),
    }),
)

const resultValidator = v.union(
    v.object({ kind: v.literal('accepted') }),
    v.object({ kind: v.literal('room.created'), code: v.string() }),
    v.object({ kind: v.literal('player.joined'), playerId: v.id('players') }),
)

export const dispatch = mutation({
    args: { event: eventValidator },
    returns: resultValidator,
    handler: async (ctx, { event }) => {
        let result:
            | { kind: 'accepted' }
            | { kind: 'room.created'; code: string }
            | { kind: 'player.joined'; playerId: Awaited<ReturnType<typeof joinRoom>> } = {
            kind: 'accepted',
        }
        switch (event.type) {
            case 'room.create':
                result = { kind: 'room.created', code: await createRoom(ctx) }
                break
            case 'player.join':
                result = {
                    kind: 'player.joined',
                    playerId: await joinRoom(ctx, event.subjects.code, event.data),
                }
                break
            case 'game.start':
                await startRoom(ctx, event.subjects.roomId)
                break
            case 'movement.roll':
                await rollMovement(ctx, event.subjects)
                break
            case 'movement.step':
                await movePlayer(ctx, { ...event.subjects, ...event.data })
                break
            case 'encounter.resolve':
                await resolveEncounter(ctx, event.subjects)
                break
            case 'shop.buy':
                await buyItem(ctx, { ...event.subjects, ...event.data })
                break
            case 'inventory.equip':
                await equipItem(ctx, { ...event.subjects, ...event.data })
                break
            case 'shop.leave':
                await leaveShop(ctx, event.subjects)
                break
        }
        await ctx.db.insert('gameEvents', {
            type: event.type,
            subjects: event.subjects,
            data: event.data,
            createdAt: Date.now(),
        })
        return result
    },
})
