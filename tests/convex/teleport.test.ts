import { expect, test } from 'vitest'
import { createScenario } from './scenario.helper'

test('ending movement on a gate teleports once and advances the turn', async () => {
    const scenario = await createScenario({
        seed: 20260910,
        players: ['Ava', 'Bo'],
        singleStepDice: true,
    })
    await scenario.patchPlayer(0, { position: 23 })
    const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[0] }
    await scenario.dispatch('Ava', { type: 'movement.roll', subjects, data: {} })
    for (const destination of [23, 27]) {
        await scenario.dispatch('Ava', {
            type: 'movement.select',
            subjects,
            data: { destination },
        })
    }
    await scenario.dispatch('Ava', {
        type: 'movement.step',
        subjects,
        data: { destination: 27 },
    })
    expect((await scenario.player(0)).position).toBe(30)
    expect((await scenario.player(0)).previousPosition).toBeUndefined()
    expect(await scenario.selection()).toBeNull()
    expect((await scenario.room()).activePlayerId).toBe(scenario.playerIds[1])
})
