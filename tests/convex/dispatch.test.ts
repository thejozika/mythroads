import { describe, expect, test } from 'vitest'
import { api } from '../../convex/_generated/api'
import { createScenario, identity, type Scenario } from './scenario.helper'

/**
 * Golden master for the dispatch envelope itself: what gets written to `gameEvents`,
 * how `commandId` deduplication behaves, which callers are refused, and the camera
 * events that are deliberately never persisted.
 */
const SEED = 20260910

async function playing(): Promise<Scenario> {
    return await createScenario({ seed: SEED, players: ['Ava', 'Bo'], singleStepDice: true })
}

function subjectsOf(scenario: Scenario, index = 0) {
    return { roomId: scenario.roomId, playerId: scenario.playerIds[index] }
}

describe('event persistence', () => {
    test('gameplay events are stored as typed envelopes', async () => {
        const scenario = await playing()
        await scenario.dispatch(
            'Ava',
            { type: 'movement.roll', subjects: subjectsOf(scenario), data: {} },
            'roll-command',
        )
        const events = await scenario.gameEvents()
        expect(events.map((event) => ('event' in event ? event.event.type : 'legacy'))).toEqual([
            'room.create',
            'player.join',
            'player.join',
            'game.start',
            'movement.roll',
        ])
        const last = events[4]
        if (!('event' in last)) throw new Error('expected a typed envelope')
        expect(last).toMatchObject({
            eventId: 'roll-command',
            commandId: 'roll-command',
            schemaVersion: 1,
            roomId: scenario.roomId,
            actorPlayerId: scenario.playerIds[0],
            authority: {
                mode: 'authenticated',
                actorPlayerId: scenario.playerIds[0],
                actorAuthId: identity('Ava').tokenIdentifier,
            },
            result: { kind: 'accepted' },
        })
        expect(last.event).toEqual({
            type: 'movement.roll',
            subjects: subjectsOf(scenario),
            data: {},
        })
    })

    test('an event dispatched without a commandId gets a synthesised eventId', async () => {
        const scenario = await playing()
        const events = await scenario.gameEvents()
        const created = events[0]
        if (!('event' in created)) throw new Error('expected a typed envelope')
        expect(created.commandId).toBeUndefined()
        expect(created.eventId).toMatch(/^[0-9a-z]+:room\.create:\{\}$/)
        expect(created.roomId).toBeUndefined()
        expect(created.result).toEqual({ kind: 'room.created', code: 'JSKM' })
    })

    test('camera events are applied but never written to gameEvents', async () => {
        const scenario = await playing()
        const before = (await scenario.gameEvents()).length
        await scenario.dispatch('Ava', {
            type: 'camera.toggle',
            subjects: subjectsOf(scenario),
            data: {},
        })
        await scenario.dispatch('Ava', {
            type: 'camera.move',
            subjects: subjectsOf(scenario),
            data: { direction: 'left' },
        })
        await scenario.dispatch('Ava', {
            type: 'camera.zoom',
            subjects: subjectsOf(scenario),
            data: { delta: 1 },
        })
        expect((await scenario.gameEvents()).length).toBe(before)
        expect(await scenario.camera()).toMatchObject({ mode: 'free', distance: 9 })
    })
})

describe('camera control', () => {
    test('toggling creates a free camera on the hero, then returns to follow', async () => {
        const scenario = await playing()
        const toggle = {
            type: 'camera.toggle' as const,
            subjects: subjectsOf(scenario),
            data: {},
        }
        await scenario.dispatch('Ava', toggle)
        const camera = await scenario.camera()
        expect(camera).toMatchObject({ mode: 'free', distance: 8 })
        expect(camera?.targetX).toBeCloseTo(-5.4, 10)
        expect(camera?.targetZ).toBeCloseTo(3.2, 10)
        await scenario.dispatch('Ava', toggle)
        expect((await scenario.camera())?.mode).toBe('follow')
    })

    test('panning and zooming clamp to the board bounds and need the free camera', async () => {
        const scenario = await playing()
        const subjects = subjectsOf(scenario)
        await expect(
            scenario.dispatch('Ava', {
                type: 'camera.move',
                subjects,
                data: { direction: 'left' },
            }),
        ).rejects.toThrow(/Free camera is not active/)
        await scenario.dispatch('Ava', { type: 'camera.toggle', subjects, data: {} })
        for (const unused of [0, 1, 2]) {
            void unused
            await scenario.dispatch('Ava', {
                type: 'camera.move',
                subjects,
                data: { direction: 'left' },
            })
        }
        await scenario.dispatch('Ava', {
            type: 'camera.move',
            subjects,
            data: { direction: 'up' },
        })
        const panned = await scenario.camera()
        expect(panned?.targetX).toBeCloseTo(-7, 10)
        expect(panned?.targetZ).toBeCloseTo(2.3, 10)

        await scenario.dispatch('Ava', {
            type: 'camera.move',
            subjects,
            data: { direction: 'right' },
        })
        await scenario.dispatch('Ava', {
            type: 'camera.move',
            subjects,
            data: { direction: 'down' },
        })
        const returned = await scenario.camera()
        expect(returned?.targetX).toBeCloseTo(-6.1, 10)
        expect(returned?.targetZ).toBeCloseTo(3.2, 10)

        for (const unused of [0, 1, 2, 3, 4]) {
            void unused
            await scenario.dispatch('Ava', { type: 'camera.zoom', subjects, data: { delta: -1 } })
        }
        expect((await scenario.camera())?.distance).toBe(5)
    })

    test('only the active hero may drive the camera', async () => {
        const scenario = await playing()
        await expect(
            scenario.dispatch('Bo', {
                type: 'camera.toggle',
                subjects: subjectsOf(scenario, 1),
                data: {},
            }),
        ).rejects.toThrow(/Only the active player can control the camera/)
    })
})

describe('commandId idempotency', () => {
    test('replaying a commandId returns the first result without re-applying it', async () => {
        const scenario = await playing()
        const event = {
            type: 'movement.roll' as const,
            subjects: subjectsOf(scenario),
            data: {},
        }
        const first = await scenario.dispatch('Ava', event, 'roll-once')
        const room = await scenario.room()
        const second = await scenario.dispatch('Ava', event, 'roll-once')
        expect(second).toEqual(first)
        expect(await scenario.room()).toMatchObject({
            rngState: room.rngState,
            rngCounter: room.rngCounter,
            lastRoll: room.lastRoll,
            remainingMoves: room.remainingMoves,
        })
        expect(
            (await scenario.gameEvents()).filter((row) => row.commandId === 'roll-once').length,
        ).toBe(1)
    })

    test('a replayed room.create returns the original code', async () => {
        const scenario = await playing()
        const repeated = await scenario.dispatch(
            'Ava',
            { type: 'room.create', subjects: {}, data: { seed: 1 } },
            'create-twice',
        )
        expect(repeated).toEqual({ kind: 'room.created', code: '8EP5' })
        expect(
            await scenario.dispatch(
                'Ava',
                { type: 'room.create', subjects: {}, data: { seed: 999 } },
                'create-twice',
            ),
        ).toEqual({ kind: 'room.created', code: '8EP5' })
    })

    test('a commandId reused for a different event silently returns the old result', async () => {
        // Pinned as-is: `priorDispatchResult` keys on the commandId alone and never
        // compares the stored event, so the second command is dropped, not applied.
        const scenario = await playing()
        await scenario.dispatch(
            'Ava',
            { type: 'movement.roll', subjects: subjectsOf(scenario), data: {} },
            'shared-command',
        )
        const before = await scenario.room()
        const result = await scenario.dispatch(
            'Ava',
            {
                type: 'movement.select',
                subjects: subjectsOf(scenario),
                data: { destination: 0 },
            },
            'shared-command',
        )
        expect(result).toEqual({ kind: 'accepted' })
        expect(await scenario.selection()).toBeNull()
        expect((await scenario.room()).message).toBe(before.message)
    })

    test('a commandId cannot be replayed by a different account', async () => {
        const scenario = await playing()
        await scenario.dispatch(
            'Ava',
            { type: 'movement.roll', subjects: subjectsOf(scenario), data: {} },
            'ava-command',
        )
        await expect(
            scenario.dispatch(
                'Bo',
                { type: 'movement.roll', subjects: subjectsOf(scenario, 1), data: {} },
                'ava-command',
            ),
        ).rejects.toThrow(/That command belongs to another account/)
    })

    test('camera commandIds are not deduplicated because camera events are not stored', async () => {
        const scenario = await playing()
        const subjects = subjectsOf(scenario)
        await scenario.dispatch('Ava', { type: 'camera.toggle', subjects, data: {} }, 'cam')
        expect((await scenario.camera())?.mode).toBe('free')
        await scenario.dispatch('Ava', { type: 'camera.toggle', subjects, data: {} }, 'cam')
        expect((await scenario.camera())?.mode).toBe('follow')
    })
})

describe('authorization refusals', () => {
    test('an account cannot act for another account hero', async () => {
        const scenario = await playing()
        for (const event of [
            { type: 'movement.roll' as const, subjects: subjectsOf(scenario), data: {} },
            {
                type: 'movement.select' as const,
                subjects: subjectsOf(scenario),
                data: { destination: 0 },
            },
            { type: 'shop.leave' as const, subjects: subjectsOf(scenario), data: {} },
        ]) {
            await expect(scenario.dispatch('Bo', event)).rejects.toThrow(
                /That hero belongs to another account/,
            )
        }
    })

    test('an anonymous caller is refused before any rule runs', async () => {
        const scenario = await playing()
        await expect(
            scenario.t.mutation(api.game.dispatch, {
                event: { type: 'movement.roll', subjects: subjectsOf(scenario), data: {} },
            }),
        ).rejects.toThrow(/Sign in to continue/)
        expect((await scenario.room()).lastRoll).toBeUndefined()
    })

    test('a hero that does not exist is refused', async () => {
        const scenario = await playing()
        const ghost = await scenario.t.run(async (ctx) => {
            const id = await ctx.db.insert('players', {
                roomId: scenario.roomId,
                name: 'Ghost',
                color: '#000000',
                position: 0,
                gold: 0,
                hp: 1,
                maxHp: 1,
                attack: 1,
                dice: [1],
                joinedAt: 0,
            })
            await ctx.db.delete(id)
            return id
        })
        await expect(
            scenario.dispatch('Ava', {
                type: 'movement.roll',
                subjects: { roomId: scenario.roomId, playerId: ghost },
                data: {},
            }),
        ).rejects.toThrow(/That hero does not exist/)
    })
})
