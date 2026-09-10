import { describe, expect, test } from 'vitest'
import type { Id } from '../../convex/_generated/dataModel'
import { createScenario, type Scenario, teleportStep } from './scenario.helper'

/**
 * Golden master for the event wheel and the shops. The event wheel draws one number in
 * [0, 100); the seeds below make the first draw land in each outcome band.
 */
const SEED = 20260910
const WHEEL_SEED = {
    coin_spring: 100,
    forest_blessing: 30,
    bridge_toll: 50,
    falling_star: 70,
    thorn_patch: 90,
}

async function heroes(): Promise<Scenario> {
    return await createScenario({ seed: SEED, players: ['Ava', 'Bo'], singleStepDice: true })
}

function subjectsOf(scenario: Scenario) {
    return { roomId: scenario.roomId, playerId: scenario.playerIds[0] }
}

async function spinWheel(scenario: Scenario, seed: number) {
    await scenario.forceRng(seed)
    await teleportStep(scenario, 0, 2, 3)
    const encounter = await scenario.encounter()
    if (!encounter) throw new Error('expected an encounter')
    return encounter
}

async function resolve(scenario: Scenario, encounterId: Id<'encounters'>) {
    await scenario.ripenEncounter()
    return await scenario.dispatch('Ava', {
        type: 'encounter.resolve',
        subjects: { ...subjectsOf(scenario), encounterId },
        data: {},
    })
}

describe('encounters', () => {
    test('each wheel band resolves into its pinned gold and health change', async () => {
        const expected = {
            coin_spring: {
                wheelIndex: 0,
                gold: 15,
                hp: 10,
                message: 'Ava: Coin Spring (+5 gold).',
            },
            forest_blessing: {
                wheelIndex: 1,
                gold: 10,
                hp: 10,
                message: 'Ava: Forest Blessing (+3 health).',
            },
            bridge_toll: { wheelIndex: 2, gold: 8, hp: 10, message: 'Ava: Bridge Toll (-2 gold).' },
            falling_star: {
                wheelIndex: 3,
                gold: 18,
                hp: 10,
                message: 'Ava: Falling Star (+8 gold).',
            },
            thorn_patch: {
                wheelIndex: 4,
                gold: 10,
                hp: 8,
                message: 'Ava: Thorn Patch (-2 health).',
            },
        }
        const observed: Record<string, unknown> = {}
        for (const [outcomeId, seed] of Object.entries(WHEEL_SEED)) {
            const scenario = await heroes()
            const encounter = await spinWheel(scenario, seed)
            expect(encounter.outcomeId).toBe(outcomeId)
            expect(encounter.status).toBe('revealing')
            expect(await resolve(scenario, encounter._id)).toEqual({ kind: 'accepted' })
            const player = await scenario.player(0)
            observed[outcomeId] = {
                wheelIndex: encounter.wheelIndex,
                gold: player.gold,
                hp: player.hp,
                message: (await scenario.room()).message,
            }
            expect((await scenario.encounter())?.status).toBe('resolved')
            expect(await scenario.room()).toMatchObject({
                phase: 'awaitingRoll',
                activePlayerId: scenario.playerIds[1],
            })
        }
        expect(observed).toEqual(expected)
    })

    test('gold cannot drop below zero and health stays between one and the maximum', async () => {
        const poor = await heroes()
        const tollEncounter = await spinWheel(poor, WHEEL_SEED.bridge_toll)
        await poor.patchPlayer(0, { gold: 1 })
        await resolve(poor, tollEncounter._id)
        expect((await poor.player(0)).gold).toBe(0)

        const hurt = await heroes()
        const thornEncounter = await spinWheel(hurt, WHEEL_SEED.thorn_patch)
        await hurt.patchPlayer(0, { hp: 1 })
        await resolve(hurt, thornEncounter._id)
        expect((await hurt.player(0)).hp).toBe(1)

        const healthy = await heroes()
        const blessing = await spinWheel(healthy, WHEEL_SEED.forest_blessing)
        await resolve(healthy, blessing._id)
        expect((await healthy.player(0)).hp).toBe(10)
    })

    test('an encounter cannot be resolved before the reveal animation finishes', async () => {
        const scenario = await heroes()
        const encounter = await spinWheel(scenario, WHEEL_SEED.coin_spring)
        await expect(
            scenario.dispatch('Ava', {
                type: 'encounter.resolve',
                subjects: { ...subjectsOf(scenario), encounterId: encounter._id },
                data: {},
            }),
        ).rejects.toThrow(/This encounter cannot be resolved now/)
        expect((await scenario.player(0)).gold).toBe(10)
    })

    test('a resolved encounter cannot be resolved twice', async () => {
        const scenario = await heroes()
        const encounter = await spinWheel(scenario, WHEEL_SEED.coin_spring)
        await resolve(scenario, encounter._id)
        await expect(
            scenario.dispatch('Ava', {
                type: 'encounter.resolve',
                subjects: { ...subjectsOf(scenario), encounterId: encounter._id },
                data: {},
            }),
        ).rejects.toThrow(/This encounter cannot be resolved now/)
        expect((await scenario.player(0)).gold).toBe(15)
    })
})

describe('shops', () => {
    async function shopping(): Promise<Scenario> {
        const scenario = await heroes()
        await teleportStep(scenario, 0, 1, 2)
        return scenario
    }

    test('buying spends gold and adds an unequipped item', async () => {
        const scenario = await shopping()
        expect(
            await scenario.dispatch('Ava', {
                type: 'shop.buy',
                subjects: subjectsOf(scenario),
                data: { itemId: 'trail_helm' },
            }),
        ).toEqual({ kind: 'accepted' })
        expect((await scenario.player(0)).gold).toBe(3)
        const items = await scenario.items(0)
        expect(items.map((item) => item.itemId)).toEqual([
            'ember_grimoire',
            'aegis_script',
            'trail_helm',
        ])
        expect(items[2].equippedSlot).toBeUndefined()
        expect((await scenario.room()).phase).toBe('shopping')
    })

    test('a purchase beyond the purse and a purchase from the wrong shop are refused', async () => {
        const scenario = await shopping()
        await scenario.patchPlayer(0, { gold: 3 })
        await expect(
            scenario.dispatch('Ava', {
                type: 'shop.buy',
                subjects: subjectsOf(scenario),
                data: { itemId: 'padded_coat' },
            }),
        ).rejects.toThrow(/You need more gold/)
        await expect(
            scenario.dispatch('Ava', {
                type: 'shop.buy',
                subjects: subjectsOf(scenario),
                data: { itemId: 'oak_blade' },
            }),
        ).rejects.toThrow(/That item is not available here/)
        await expect(
            scenario.dispatch('Ava', {
                type: 'shop.buy',
                subjects: subjectsOf(scenario),
                data: { itemId: 'no_such_item' },
            }),
        ).rejects.toThrow(/That item is not available here/)
        expect((await scenario.player(0)).gold).toBe(3)
        expect((await scenario.items(0)).length).toBe(2)
    })

    test('a bought item equips into a slot it declares and no other', async () => {
        const scenario = await shopping()
        await scenario.dispatch('Ava', {
            type: 'shop.buy',
            subjects: subjectsOf(scenario),
            data: { itemId: 'trail_helm' },
        })
        const helm = (await scenario.items(0))[2]
        await expect(
            scenario.dispatch('Ava', {
                type: 'inventory.equip',
                subjects: { playerId: scenario.playerIds[0], playerItemId: helm._id },
                data: { slot: 'weapon' },
            }),
        ).rejects.toThrow(/That item cannot be equipped there/)
        await scenario.dispatch('Ava', {
            type: 'inventory.equip',
            subjects: { playerId: scenario.playerIds[0], playerItemId: helm._id },
            data: { slot: 'helmet' },
        })
        expect((await scenario.items(0))[2].equippedSlot).toBe('helmet')
    })

    test('leaving the shop passes the turn and clears the shop', async () => {
        const scenario = await shopping()
        expect(
            await scenario.dispatch('Ava', {
                type: 'shop.leave',
                subjects: subjectsOf(scenario),
                data: {},
            }),
        ).toEqual({ kind: 'accepted' })
        const room = await scenario.room()
        expect(room).toMatchObject({
            phase: 'awaitingRoll',
            remainingMoves: 0,
            round: 1,
            activePlayerId: scenario.playerIds[1],
            message: 'Ava finished shopping.',
        })
        expect(room.shopKind).toBeUndefined()
        await expect(
            scenario.dispatch('Ava', {
                type: 'shop.buy',
                subjects: subjectsOf(scenario),
                data: { itemId: 'trail_helm' },
            }),
        ).rejects.toThrow(/That item is not available here/)
        await expect(
            scenario.dispatch('Ava', {
                type: 'shop.leave',
                subjects: subjectsOf(scenario),
                data: {},
            }),
        ).rejects.toThrow(/You are not shopping now/)
    })
})
