import { describe, expect, test } from 'vitest'
import { createScenario, type Scenario, teleportStep } from './scenario.helper'

/** Golden master for what each space kind does when a hero stops on it. */
const SEED = 20260910

async function twoHeroes(): Promise<Scenario> {
    return await createScenario({ seed: SEED, players: ['Ava', 'Bo'], singleStepDice: true })
}

describe('landing on a space', () => {
    test('a combat space opens a battle against the space enemy', async () => {
        const scenario = await twoHeroes()
        await teleportStep(scenario, 0, 0, 1)
        const room = await scenario.room()
        expect(room).toMatchObject({
            phase: 'combatAttack',
            remainingMoves: 0,
            message: 'Ava faces a Fen Slime!',
        })
        expect(await scenario.combat()).toMatchObject({
            spaceId: 1,
            enemyName: 'Fen Slime',
            enemyElement: 'water',
            enemyHp: 11,
            enemyMaxHp: 11,
            enemyAttack: 2,
            enemyDefense: 2,
            enemyMagic: 3,
            enemyAthletics: 1,
            enemyAgility: 2,
            reward: 6,
            round: 1,
            phase: 'attack',
            message: 'Choose how to attack the Fen Slime.',
        })
        expect(room.activePlayerId).toBe(scenario.playerIds[0])
    })

    test('the enemy roster cycles with the space id', async () => {
        const scenario = await twoHeroes()
        const enemies: string[] = []
        for (const [from, to] of [
            [0, 1],
            [11, 4],
            [8, 7],
            [12, 13],
        ]) {
            await teleportStep(scenario, 0, from, to)
            const combat = await scenario.combat()
            enemies.push(`${to}:${combat?.enemyName}`)
            await scenario.t.run(async (ctx) => {
                const rows = await ctx.db.query('combats').take(10)
                for (const row of rows) await ctx.db.delete(row._id)
            })
        }
        expect(enemies).toEqual(['1:Fen Slime', '4:Mossback Boar', '7:Gale Wolf', '13:Fen Slime'])
    })

    test('a shop space parks the hero in the shop phase', async () => {
        const scenario = await twoHeroes()
        await teleportStep(scenario, 0, 1, 2)
        expect(await scenario.room()).toMatchObject({
            phase: 'shopping',
            shopKind: 'armoury',
            remainingMoves: 0,
            message: 'Ava entered the Armoury Junction.',
        })
    })

    test('an event space spins the wheel and stores the encounter', async () => {
        const scenario = await twoHeroes()
        await scenario.forceRng(100)
        await teleportStep(scenario, 0, 2, 3)
        expect(await scenario.room()).toMatchObject({
            phase: 'revealingEncounter',
            remainingMoves: 0,
            message: 'Ava spins the event wheel!',
        })
        expect(await scenario.encounter()).toMatchObject({
            spaceId: 3,
            kind: 'event',
            outcomeId: 'coin_spring',
            title: 'Coin Spring',
            goldDelta: 5,
            hpDelta: 0,
            wheelIndex: 0,
            status: 'revealing',
        })
    })

    test('the castle heals the hero to full and passes the turn', async () => {
        const scenario = await twoHeroes()
        await scenario.patchPlayer(0, { hp: 3 })
        await teleportStep(scenario, 0, 1, 0)
        expect(await scenario.player(0)).toMatchObject({ hp: 10, position: 0 })
        expect(await scenario.room()).toMatchObject({
            phase: 'awaitingRoll',
            activePlayerId: scenario.playerIds[1],
            round: 1,
            message: 'Ava rested at Hearthkeep and recovered all health.',
        })
    })
})
