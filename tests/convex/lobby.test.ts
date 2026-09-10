import { convexTest } from 'convex-test'
import { describe, expect, test } from 'vitest'
import { api } from '../../convex/_generated/api'
import schema from '../../convex/schema'
import { convexModules, createScenario, identity } from './scenario.helper'

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
