import { convexTest } from 'convex-test'
import { afterEach, describe, expect, test, vi } from 'vitest'
import { api } from '../../convex/_generated/api'
import type { Id } from '../../convex/_generated/dataModel'
import type { GameEvent } from '../../convex/events/validators'
import schema from '../../convex/schema'
import { convexModules, createScenario, identity } from './scenario.helper'

const MODULUS = 2147483647

/** Create a room through the public mutation and return its code and row. */
async function createRoom(seed: number, as = 'Ava') {
    const t = convexTest(schema, convexModules)
    const created = await t.withIdentity(identity(as)).mutation(api.game.dispatch, {
        event: { type: 'room.create', subjects: {}, data: { seed } },
    })
    if (created.kind !== 'room.created') throw new Error('expected a room')
    const room = await t.run(async (ctx) =>
        ctx.db
            .query('rooms')
            .withIndex('by_code', (query) => query.eq('code', created.code))
            .unique(),
    )
    if (!room) throw new Error('expected a room row')
    return { t, code: created.code, room }
}

const join = (code: string, name: string, color: string): GameEvent => ({
    type: 'player.join',
    subjects: { code },
    data: { name, color },
})

/**
 * Golden master for the lobby: room creation from a seed, joining, rejoining and
 * the host-only start. Values are the ones today's Convex code produces.
 */
describe('lobby', () => {
    test('a seeded room.create returns a deterministic code and a lobby row', async () => {
        const scenario = await createScenario({
            seed: 20260910,
            players: ['Ava'],
            start: false,
        })
        expect(scenario.code).toBe('JSKM')
        const room = await scenario.room()
        expect(room).toMatchObject({
            code: 'JSKM',
            status: 'lobby',
            phase: 'awaitingRoll',
            remainingMoves: 0,
            round: 1,
            message: 'Scan the code to join the adventure.',
            hostAuthId: identity('Ava').tokenIdentifier,
            rngState: 1570710475,
            rngCounter: 4,
        })
        expect(room.activePlayerId).toBeUndefined()
        expect(room.lastRoll).toBeUndefined()
    })

    test('player.join creates the starting hero and their two grimoires', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava'], start: false })
        const player = await scenario.player(0)
        expect(player).toMatchObject({
            name: 'Ava',
            color: '#4bd3c2',
            position: 0,
            gold: 10,
            hp: 10,
            maxHp: 10,
            attack: 2,
            defense: 2,
            magic: 2,
            athletics: 2,
            agility: 2,
            dice: [4, 6],
            authId: identity('Ava').tokenIdentifier,
        })
        expect(player.previousPosition).toBeUndefined()
        const items = await scenario.items(0)
        expect(items.map((item) => [item.itemId, item.equippedSlot])).toEqual([
            ['ember_grimoire', 'offensiveMagic'],
            ['aegis_script', 'defensiveMagic'],
        ])
    })

    test('re-joining with the same account returns the existing hero', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava'], start: false })
        const again = await scenario.dispatch('Ava', {
            type: 'player.join',
            subjects: { code: scenario.code },
            data: { name: 'Ava-renamed', color: '#000000' },
        })
        expect(again).toEqual({ kind: 'player.joined', playerId: scenario.playerIds[0] })
        expect((await scenario.players()).length).toBe(1)
    })

    test('join refuses an unknown room, a blank name and a taken hero name', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava'], start: false })
        await expect(
            scenario.dispatch('Bo', {
                type: 'player.join',
                subjects: { code: 'ZZZZ' },
                data: { name: 'Bo', color: '#ef6b73' },
            }),
        ).rejects.toThrow(/That room does not exist/)
        await expect(
            scenario.dispatch('Bo', {
                type: 'player.join',
                subjects: { code: scenario.code },
                data: { name: '   ', color: '#ef6b73' },
            }),
        ).rejects.toThrow(/Choose a hero name/)
        await expect(
            scenario.dispatch('Bo', {
                type: 'player.join',
                subjects: { code: scenario.code },
                data: { name: 'Ava', color: '#4bd3c2' },
            }),
        ).rejects.toThrow(/That hero name belongs to another account/)
    })

    test('a room holds at most four heroes', async () => {
        const scenario = await createScenario({
            seed: 20260910,
            players: ['Ava', 'Bo', 'Cy', 'Di'],
            start: false,
        })
        expect((await scenario.players()).length).toBe(4)
        await expect(
            scenario.dispatch('Ed', {
                type: 'player.join',
                subjects: { code: scenario.code },
                data: { name: 'Ed', color: '#ffffff' },
            }),
        ).rejects.toThrow(/That room is full/)
    })

    test('only the host can start, and starting seats the first hero', async () => {
        const scenario = await createScenario({
            seed: 20260910,
            players: ['Ava', 'Bo'],
            start: false,
        })
        const event = {
            type: 'game.start' as const,
            subjects: { roomId: scenario.roomId },
            data: {},
        }
        await expect(scenario.dispatch('Bo', event)).rejects.toThrow(/Only the host can start/)
        expect(await scenario.dispatch('Ava', event)).toEqual({ kind: 'accepted' })
        const room = await scenario.room()
        expect(room).toMatchObject({
            status: 'playing',
            phase: 'awaitingRoll',
            activePlayerId: scenario.playerIds[0],
            message: 'Ava, roll your movement dice.',
        })
    })

    test('starting an already started room is an accepted no-op', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava', 'Bo'] })
        await scenario.patchRoom({ activePlayerId: scenario.playerIds[1] })
        const result = await scenario.dispatch('Ava', {
            type: 'game.start',
            subjects: { roomId: scenario.roomId },
            data: {},
        })
        expect(result).toEqual({ kind: 'accepted' })
        expect((await scenario.room()).activePlayerId).toBe(scenario.playerIds[1])
    })

    test('an empty room cannot start and a started room refuses new heroes', async () => {
        const t = convexTest(schema, convexModules)
        const created = await t.withIdentity(identity('Ava')).mutation(api.game.dispatch, {
            event: { type: 'room.create', subjects: {}, data: { seed: 7 } },
        })
        if (created.kind !== 'room.created') throw new Error('expected a room')
        const roomId = await t.run(async (ctx) => {
            const room = await ctx.db
                .query('rooms')
                .withIndex('by_code', (query) => query.eq('code', created.code))
                .unique()
            if (!room) throw new Error('expected a room row')
            return room._id
        })
        await expect(
            t.withIdentity(identity('Ava')).mutation(api.game.dispatch, {
                event: { type: 'game.start', subjects: { roomId }, data: {} },
            }),
        ).rejects.toThrow(/At least one hero must join/)

        const scenario = await createScenario({ seed: 20260910, players: ['Ava'] })
        await expect(
            scenario.dispatch('Bo', {
                type: 'player.join',
                subjects: { code: scenario.code },
                data: { name: 'Bo', color: '#ef6b73' },
            }),
        ).rejects.toThrow(/That adventure has started/)
    })
})

describe('untrusted numbers at the boundary', () => {
    test.each([
        [-1, 1],
        [0.5, 0],
        [1e300, 1e300],
    ])('seed %s is coerced to trunc(|seed|) and yields a sane generator', async (seed, coerced) => {
        const untrusted = await createRoom(seed)
        const trusted = await createRoom(coerced)
        expect(untrusted.code).toBe(trusted.code)
        expect(untrusted.room.rngState).toBe(trusted.room.rngState)
        const state = untrusted.room.rngState ?? Number.NaN
        expect(Number.isInteger(state)).toBe(true)
        expect(state).toBeGreaterThan(0)
        expect(state).toBeLessThan(MODULUS)
        expect(untrusted.room.rngCounter).toBe(4)
    })

    test('dice still work in a room created from a hostile seed', async () => {
        const scenario = await createScenario({ seed: -1, players: ['Ava'] })
        await scenario.dispatch('Ava', {
            type: 'movement.roll',
            subjects: { roomId: scenario.roomId, playerId: scenario.playerIds[0] },
            data: {},
        })
        const room = await scenario.room()
        expect(room.lastRoll).toHaveLength(2)
        const [four, six] = room.lastRoll ?? []
        expect(Number.isInteger(four) && four >= 1 && four <= 4).toBe(true)
        expect(Number.isInteger(six) && six >= 1 && six <= 6).toBe(true)
        expect(Number.isInteger(room.rngState)).toBe(true)
        expect(room.rngState).toBeLessThan(MODULUS)
        expect(room.rngCounter).toBe(6)
    })

    test('two rooms created from seed -1 both succeed with distinct codes', async () => {
        const t = convexTest(schema, convexModules)
        const create = () =>
            t.withIdentity(identity('Ava')).mutation(api.game.dispatch, {
                event: { type: 'room.create', subjects: {}, data: { seed: -1 } },
            })
        const first = await create()
        const second = await create()
        if (first.kind !== 'room.created' || second.kind !== 'room.created') {
            throw new Error('expected two rooms')
        }
        expect(first.code).not.toBe(second.code)
        const rooms = await t.run(async (ctx) => ctx.db.query('rooms').take(4))
        expect(rooms.map((room) => room.rngCounter)).toEqual([4, 8])
        for (const room of rooms) expect(room.rngState).toBeLessThan(MODULUS)
    })

    test('a non-finite destination is refused, a fractional one is truncated', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava'] })
        const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[0] }
        await scenario.dispatch('Ava', { type: 'movement.roll', subjects, data: {} })
        await expect(
            scenario.dispatch('Ava', {
                type: 'movement.select',
                subjects,
                data: { destination: Number.POSITIVE_INFINITY },
            }),
        ).rejects.toThrow(/That destination cannot be selected/)
        await scenario.dispatch('Ava', {
            type: 'movement.select',
            subjects,
            data: { destination: -0.75 },
        })
        expect(await scenario.selection()).toMatchObject({ destination: 0, path: [] })
    })
})

describe('client strings are bounded', () => {
    test('a colour of any length is trimmed to sixteen characters', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava'], start: false })
        const joined = await scenario.dispatch(
            'Bo',
            join(scenario.code, 'Bo', `  ${'#'.repeat(200_000)}  `),
        )
        expect(joined.kind).toBe('player.joined')
        const bo = (await scenario.players()).find((hero) => hero.name === 'Bo')
        expect(bo?.color).toBe('#'.repeat(16))
    })

    test('reclaiming an unowned hero with an oversized colour is a refusal, not a crash', async () => {
        const scenario = await createScenario({ seed: 20260910, players: ['Ava'], start: false })
        await scenario.patchPlayer(0, { authId: undefined })
        await expect(
            scenario.dispatch('Bo', join(scenario.code, 'Ava', 'x'.repeat(200_000))),
        ).rejects.toThrow(/Select their original color to rejoin/)
        expect(await scenario.dispatch('Bo', join(scenario.code, 'Ava', '#4BD3C2'))).toEqual({
            kind: 'player.joined',
            playerId: scenario.playerIds[0],
        })
        expect((await scenario.player(0)).authId).toBe(identity('Bo').tokenIdentifier)
    })
})

describe('the development bypass', () => {
    afterEach(() => vi.unstubAllEnvs())

    test('anonymous joiners each get their own unowned hero', async () => {
        vi.stubEnv('DEV_NO_AUTH', 'true')
        const t = convexTest(schema, convexModules)
        const created = await t.mutation(api.game.dispatch, {
            event: { type: 'room.create', subjects: {}, data: { seed: 20260910 } },
        })
        if (created.kind !== 'room.created') throw new Error('expected a room')
        const ava = await t.mutation(api.game.dispatch, {
            event: join(created.code, 'Ava', '#4bd3c2'),
        })
        const bo = await t.mutation(api.game.dispatch, {
            event: join(created.code, 'Bo', '#ef6b73'),
        })
        if (ava.kind !== 'player.joined' || bo.kind !== 'player.joined') {
            throw new Error('expected two heroes')
        }
        expect(ava.playerId).not.toBe(bo.playerId)
        const rows = await t.run(async (ctx) => ({
            room: await ctx.db
                .query('rooms')
                .withIndex('by_code', (query) => query.eq('code', created.code))
                .unique(),
            heroes: await ctx.db.query('players').take(4),
        }))
        expect(rows.room?.hostAuthId).toBeUndefined()
        expect(rows.heroes.map((hero) => [hero.name, hero.authId])).toEqual([
            ['Ava', undefined],
            ['Bo', undefined],
        ])
        const roomId = rows.room?._id as Id<'rooms'>
        expect(
            await t.mutation(api.game.dispatch, {
                event: { type: 'game.start', subjects: { roomId }, data: {} },
            }),
        ).toEqual({ kind: 'accepted' })
    })
})
