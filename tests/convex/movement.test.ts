import { describe, expect, test } from 'vitest'
import { createScenario, type Scenario } from './scenario.helper'

/**
 * Golden master for roll → select → cancel → select → step. The seeded room stream
 * makes the first roll of seed 20260910 exactly [4, 5].
 */
const SEED = 20260910

async function moving(): Promise<Scenario> {
    const scenario = await createScenario({ seed: SEED, players: ['Ava', 'Bo'] })
    await scenario.dispatch('Ava', {
        type: 'movement.roll',
        subjects: { roomId: scenario.roomId, playerId: scenario.playerIds[0] },
        data: {},
    })
    return scenario
}

function subjectsOf(scenario: Scenario) {
    return { roomId: scenario.roomId, playerId: scenario.playerIds[0] }
}

async function select(scenario: Scenario, destination: number) {
    return await scenario.dispatch('Ava', {
        type: 'movement.select',
        subjects: subjectsOf(scenario),
        data: { destination },
    })
}

describe('movement', () => {
    test('a roll consumes the room stream and opens the moving phase', async () => {
        const scenario = await moving()
        const room = await scenario.room()
        expect(room).toMatchObject({
            lastRoll: [4, 5],
            remainingMoves: 9,
            phase: 'moving',
            rngState: 1255379524,
            rngCounter: 6,
            message: 'Ava rolled 9. Press Y to choose a destination.',
        })
        await expect(
            scenario.dispatch('Ava', {
                type: 'movement.roll',
                subjects: subjectsOf(scenario),
                data: {},
            }),
        ).rejects.toThrow(/You cannot roll now/)
    })

    test('route planning must start on the hero and follows real roads', async () => {
        const scenario = await moving()
        await expect(select(scenario, 1)).rejects.toThrow(/Start route planning from the hero/)
        await select(scenario, 0)
        expect(await scenario.selection()).toMatchObject({ destination: 0, path: [] })
        expect((await scenario.room()).message).toBe(
            'Planning through Hearthkeep. 9 movement left.',
        )

        await select(scenario, 1)
        expect(await scenario.selection()).toMatchObject({ destination: 1, path: [1] })
        expect((await scenario.room()).message).toBe('Planning through Mossling. 8 movement left.')

        await expect(select(scenario, 5)).rejects.toThrow(/That road cannot be used from here/)
    })

    test('re-selecting the previous space refunds a step', async () => {
        const scenario = await moving()
        await select(scenario, 0)
        await select(scenario, 1)
        await select(scenario, 2)
        expect(await scenario.selection()).toMatchObject({ destination: 2, path: [1, 2] })
        await select(scenario, 1)
        expect(await scenario.selection()).toMatchObject({ destination: 1, path: [1] })
        await select(scenario, 0)
        expect(await scenario.selection()).toMatchObject({ destination: 0, path: [] })
    })

    test('cancel drops the selection and select rebuilds it', async () => {
        const scenario = await moving()
        await select(scenario, 0)
        await select(scenario, 1)
        await scenario.dispatch('Ava', {
            type: 'movement.cancel',
            subjects: subjectsOf(scenario),
            data: {},
        })
        expect(await scenario.selection()).toBeNull()
        expect((await scenario.room()).message).toBe('Press Y to choose a destination.')
        await expect(select(scenario, 1)).rejects.toThrow(/Start route planning from the hero/)
        await select(scenario, 0)
        await select(scenario, 1)
        expect(await scenario.selection()).toMatchObject({ path: [1] })
    })

    test('a full nine-step route travels and lands the hero at Moon Shrine', async () => {
        const scenario = await moving()
        await select(scenario, 0)
        for (const destination of [1, 2, 3, 4, 5, 6, 7, 8, 9]) await select(scenario, destination)
        expect((await scenario.room()).message).toBe(
            'Route ends at Moon Shrine. Press A to travel.',
        )

        await scenario.dispatch('Ava', {
            type: 'movement.step',
            subjects: subjectsOf(scenario),
            data: { destination: 9 },
        })
        expect(await scenario.player(0)).toMatchObject({ position: 9, previousPosition: 8 })
        expect(await scenario.selection()).toBeNull()
        expect((await scenario.room()).phase).toBe('revealingEncounter')
    })

    test('an unfinished or mismatched route cannot be travelled', async () => {
        const scenario = await moving()
        await select(scenario, 0)
        await select(scenario, 1)
        await expect(
            scenario.dispatch('Ava', {
                type: 'movement.step',
                subjects: subjectsOf(scenario),
                data: { destination: 1 },
            }),
        ).rejects.toThrow(/That route is not available/)
        for (const destination of [2, 3, 4, 5, 6, 7, 8, 9]) await select(scenario, destination)
        await expect(
            scenario.dispatch('Ava', {
                type: 'movement.step',
                subjects: subjectsOf(scenario),
                data: { destination: 8 },
            }),
        ).rejects.toThrow(/That route is not available/)
    })

    test('a route may not exceed the rolled movement', async () => {
        const scenario = await createScenario({
            seed: SEED,
            players: ['Ava'],
            singleStepDice: true,
        })
        await scenario.dispatch('Ava', {
            type: 'movement.roll',
            subjects: subjectsOf(scenario),
            data: {},
        })
        expect((await scenario.room()).remainingMoves).toBe(1)
        await select(scenario, 0)
        await select(scenario, 1)
        await expect(select(scenario, 2)).rejects.toThrow(/That road cannot be used from here/)
    })

    test('the 12 → 13 bridge is one-way', async () => {
        const scenario = await createScenario({ seed: SEED, players: ['Ava'] })
        await scenario.patchRoom({ remainingMoves: 1, phase: 'moving' })

        await scenario.patchPlayer(0, { position: 12 })
        await select(scenario, 12)
        await select(scenario, 13)
        expect(await scenario.selection()).toMatchObject({ destination: 13, path: [13] })

        await scenario.dispatch('Ava', {
            type: 'movement.cancel',
            subjects: subjectsOf(scenario),
            data: {},
        })
        await scenario.patchPlayer(0, { position: 13 })
        await select(scenario, 13)
        await expect(select(scenario, 12)).rejects.toThrow(/That road cannot be used from here/)
    })
})
