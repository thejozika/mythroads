/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */
import { type Infer, v } from 'convex/values'

export const gameEventValidator = v.union(
    v.object({
        type: v.literal('room.create'),
        subjects: v.object({}),
        data: v.object({ seed: v.optional(v.number()) }),
    }),
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
                v.literal('emberBlast'),
                v.literal('scorchArmor'),
                v.literal('tideNeedle'),
                v.literal('undertow'),
                v.literal('galeBlade'),
                v.literal('windShear'),
                v.literal('stoneCrash'),
                v.literal('calcify'),
            ),
        }),
    }),
    v.object({
        type: v.literal('combat.guard'),
        subjects: v.object({ roomId: v.id('rooms'), playerId: v.id('players') }),
        data: v.object({
            guard: v.union(
                v.literal('high'),
                v.literal('side'),
                v.literal('brace'),
                v.literal('ward'),
            ),
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
                v.literal('offensiveMagic'),
                v.literal('defensiveMagic'),
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

export const dispatchResultValidator = v.union(
    v.object({ kind: v.literal('accepted') }),
    v.object({ kind: v.literal('room.created'), code: v.string() }),
    v.object({ kind: v.literal('player.joined'), playerId: v.id('players') }),
)

export type GameEvent = Infer<typeof gameEventValidator>
export type DispatchResult = Infer<typeof dispatchResultValidator>
