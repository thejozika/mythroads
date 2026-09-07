import { v } from 'convex/values'
import { mutation } from './_generated/server'
import { moveCamera, toggleCamera, zoomCamera } from './camera'
import { chooseAttack, chooseGuard } from './combat'
import { resolveEncounter } from './encounters'
import {
    cancelDestination,
    createRoom,
    joinRoom,
    movePlayer,
    rollMovement,
    selectDestination,
    startRoom,
} from './rooms'
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
        type: v.literal('movement.select'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({ destination: v.number() }),
    }),
    v.object({
        type: v.literal('movement.cancel'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({}),
    }),
    v.object({
        type: v.literal('movement.step'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({ destination: v.number() }),
    }),
    v.object({
        type: v.literal('combat.attack'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({
            attack: v.union(
                v.literal('stab'),
                v.literal('chargeHigh'),
                v.literal('chargeSide'),
                v.literal('leap'),
                v.literal('fire'),
                v.literal('water'),
                v.literal('wind'),
            ),
        }),
    }),
    v.object({
        type: v.literal('combat.guard'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({
            guard: v.union(v.literal('high'), v.literal('side'), v.literal('brace')),
        }),
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
    v.object({
        type: v.literal('camera.toggle'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({}),
    }),
    v.object({
        type: v.literal('camera.move'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({
            direction: v.union(
                v.literal('up'),
                v.literal('down'),
                v.literal('left'),
                v.literal('right'),
            ),
        }),
    }),
    v.object({
        type: v.literal('camera.zoom'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({ delta: v.union(v.literal(-1), v.literal(1)) }),
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
            case 'movement.select':
                await selectDestination(ctx, { ...event.subjects, ...event.data })
                break
            case 'movement.cancel':
                await cancelDestination(ctx, event.subjects)
                break
            case 'movement.step':
                await movePlayer(ctx, { ...event.subjects, ...event.data })
                break
            case 'combat.attack':
                await chooseAttack(ctx, event.subjects, event.data.attack)
                break
            case 'combat.guard':
                await chooseGuard(ctx, event.subjects, event.data.guard)
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
            case 'camera.toggle':
                await toggleCamera(ctx, event.subjects)
                break
            case 'camera.move':
                await moveCamera(ctx, event.subjects, event.data.direction)
                break
            case 'camera.zoom':
                await zoomCamera(ctx, event.subjects, event.data.delta)
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
