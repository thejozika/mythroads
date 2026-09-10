import { describe, expect, test } from 'vitest'
import { createScenario, type Scenario } from './scenario.helper'

/**
 * Golden master for the turn cycle: heroes act in join order, the round counter ticks
 * over when the last hero in the order finishes, and nobody else may act meanwhile.
 */
const SEED = 20260910

/** Walk the active hero from Mossling back onto the castle, which ends their turn. */
async function takeCastleTurn(scenario: Scenario, index: number) {
    const as = scenario.names[index]
    const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[index] }
    await scenario.patchPlayer(index, { position: 1, previousPosition: undefined })
    await scenario.patchRoom({ phase: 'moving', remainingMoves: 1 })
    await scenario.dispatch(as, { type: 'movement.select', subjects, data: { destination: 1 } })
    await scenario.dispatch(as, { type: 'movement.select', subjects, data: { destination: 0 } })
    await scenario.dispatch(as, { type: 'movement.step', subjects, data: { destination: 0 } })
}

describe('turn order', () => {
    test('four heroes act in join order and the round ticks after the last of them', async () => {
        const scenario = await createScenario({
            seed: SEED,
            players: ['Ava', 'Bo', 'Cy', 'Di'],
            singleStepDice: true,
        })
        const players = await scenario.players()
        expect(players.map((player) => player.name)).toEqual(['Ava', 'Bo', 'Cy', 'Di'])
        expect(await scenario.room()).toMatchObject({
            round: 1,
            activePlayerId: scenario.playerIds[0],
        })

        const observed: string[] = []
        for (const turn of [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) {
            await takeCastleTurn(scenario, turn % 4)
            const room = await scenario.room()
            const next = scenario.playerIds.indexOf(room.activePlayerId ?? scenario.playerIds[0])
            observed.push(`r${room.round}:${scenario.names[next]}`)
        }
        expect(observed).toEqual([
            'r1:Bo',
            'r1:Cy',
            'r1:Di',
            'r2:Ava',
            'r2:Bo',
            'r2:Cy',
            'r2:Di',
            'r3:Ava',
            'r3:Bo',
            'r3:Cy',
            'r3:Di',
            'r4:Ava',
        ])
    })

    test('a solo hero keeps the turn and increments the round every time', async () => {
        const scenario = await createScenario({
            seed: SEED,
            players: ['Ava'],
            singleStepDice: true,
        })
        for (const turn of [0, 1, 2]) {
            void turn
            await takeCastleTurn(scenario, 0)
        }
        expect(await scenario.room()).toMatchObject({
            round: 4,
            activePlayerId: scenario.playerIds[0],
            phase: 'awaitingRoll',
        })
    })

    test('a hero who is not on turn cannot roll or move', async () => {
        const scenario = await createScenario({
            seed: SEED,
            players: ['Ava', 'Bo'],
            singleStepDice: true,
        })
        const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[1] }
        await expect(
            scenario.dispatch('Bo', { type: 'movement.roll', subjects, data: {} }),
        ).rejects.toThrow(/You cannot roll now/)
        await expect(
            scenario.dispatch('Bo', {
                type: 'movement.select',
                subjects,
                data: { destination: 0 },
            }),
        ).rejects.toThrow(/That destination cannot be selected/)
        await expect(
            scenario.dispatch('Bo', { type: 'movement.cancel', subjects, data: {} }),
        ).rejects.toThrow(/There is no movement selection to cancel/)
    })

    test('a turn that ends clears the encounter, combat and shop pointers', async () => {
        const scenario = await createScenario({
            seed: SEED,
            players: ['Ava', 'Bo'],
            singleStepDice: true,
        })
        await scenario.patchRoom({ shopKind: 'armoury', phase: 'shopping' })
        await scenario.dispatch('Ava', {
            type: 'shop.leave',
            subjects: { roomId: scenario.roomId, playerId: scenario.playerIds[0] },
            data: {},
        })
        const room = await scenario.room()
        expect(room.shopKind).toBeUndefined()
        expect(room.activeCombatId).toBeUndefined()
        expect(room.activeEncounterId).toBeUndefined()
        expect(room).toMatchObject({
            remainingMoves: 0,
            phase: 'awaitingRoll',
            activePlayerId: scenario.playerIds[1],
            round: 1,
        })
    })
})
