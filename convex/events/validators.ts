import { type Infer, v } from 'convex/values'

const roomPlayerSubjects = v.object({ roomId: v.id('rooms'), playerId: v.id('players') })

export const gameEventValidator = v.union(
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
        subjects: roomPlayerSubjects,
        data: v.object({}),
    }),
    v.object({
        type: v.literal('movement.select'),
        subjects: roomPlayerSubjects,
        data: v.object({ destination: v.number() }),
    }),
    v.object({
        type: v.literal('movement.cancel'),
        subjects: roomPlayerSubjects,
        data: v.object({}),
    }),
    v.object({
        type: v.literal('movement.step'),
        subjects: roomPlayerSubjects,
        data: v.object({ destination: v.number() }),
    }),
    v.object({
        type: v.literal('combat.attack'),
        subjects: roomPlayerSubjects,
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
        subjects: roomPlayerSubjects,
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
        subjects: roomPlayerSubjects,
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
    v.object({ type: v.literal('shop.leave'), subjects: roomPlayerSubjects, data: v.object({}) }),
    v.object({
        type: v.literal('camera.toggle'),
        subjects: roomPlayerSubjects,
        data: v.object({}),
    }),
    v.object({
        type: v.literal('camera.move'),
        subjects: roomPlayerSubjects,
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
        subjects: roomPlayerSubjects,
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
