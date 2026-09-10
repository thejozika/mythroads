import { describe, expect, test } from 'vitest'
import { createScenario, type Scenario, teleportStep } from './scenario.helper'

/**
 * Golden master for the battle at space 1 (Fen Slime, water, 11 HP, reward 6) fought by
 * a starting hero (all stats 2, 10 HP, 10 gold, Ember Grimoire equipped).
 *
 * The room random stream is forced before every choice: the first draw picks the enemy
 * guard (attack phase) or the enemy attack (defend phase), the second draw is the hit
 * roll. The seeds below were chosen so the named stance comes out and the strike lands.
 */
const SEED = 20260910
const GUARD_SEED = { high: 4, side: 3, brace: 2, ward: 9 } as const
const GUARD_SEED_MISS = { high: 16, side: 23, brace: 10, ward: 5 } as const
const ENEMY_SEED = { stab: 6, chargeHigh: 7, chargeSide: 2, leap: 3, tideNeedle: 4, undertow: 11 }
const NO_PENALTIES = {
    enemyDefensePenalty: undefined,
    enemyMagicPenalty: undefined,
    enemyAthleticsPenalty: undefined,
    enemyAgilityPenalty: undefined,
    playerDefensePenalty: undefined,
    playerMagicPenalty: undefined,
    playerAthleticsPenalty: undefined,
    playerAgilityPenalty: undefined,
}

async function battle(): Promise<Scenario> {
    const scenario = await createScenario({
        seed: SEED,
        players: ['Ava', 'Bo'],
        singleStepDice: true,
    })
    await teleportStep(scenario, 0, 0, 1)
    return scenario
}

async function reset(scenario: Scenario, phase: 'attack' | 'defend', rng: number) {
    const combat = await scenario.combat()
    if (!combat) throw new Error('expected a live combat')
    await scenario.t.run(async (ctx) => {
        await ctx.db.patch(combat._id, { enemyHp: 11, phase, round: 1, ...NO_PENALTIES })
    })
    await scenario.patchRoom({ phase: phase === 'attack' ? 'combatAttack' : 'combatDefend' })
    await scenario.patchPlayer(0, { hp: 10, gold: 10 })
    await scenario.forceRng(rng)
}

function subjectsOf(scenario: Scenario) {
    return { roomId: scenario.roomId, playerId: scenario.playerIds[0] }
}

describe('combat', () => {
    test('every attack against every enemy guard deals its pinned damage', async () => {
        const expected: Record<string, [number, string]> = {
            'stab/high': [1, 'Quick stab met High guard: neutral, 1 damage.'],
            'stab/side': [1, 'Quick stab met Side guard: neutral, 1 damage.'],
            'stab/brace': [1, 'Quick stab met Brace: neutral, 1 damage.'],
            'stab/ward': [2, 'Quick stab met Arcane ward: strong, 2 damage.'],
            'chargeHigh/high': [1, 'High charge met High guard: weak, 1 damage.'],
            'chargeHigh/side': [4, 'High charge met Side guard: strong, 4 damage.'],
            'chargeHigh/brace': [2, 'High charge met Brace: neutral, 2 damage.'],
            'chargeHigh/ward': [4, 'High charge met Arcane ward: strong, 4 damage.'],
            'chargeSide/high': [2, 'Side rush met High guard: neutral, 2 damage.'],
            'chargeSide/side': [1, 'Side rush met Side guard: weak, 1 damage.'],
            'chargeSide/brace': [4, 'Side rush met Brace: strong, 4 damage.'],
            'chargeSide/ward': [4, 'Side rush met Arcane ward: strong, 4 damage.'],
            'leap/high': [4, 'Leaping strike met High guard: strong, 4 damage.'],
            'leap/side': [2, 'Leaping strike met Side guard: neutral, 2 damage.'],
            'leap/brace': [1, 'Leaping strike met Brace: weak, 1 damage.'],
            'leap/ward': [4, 'Leaping strike met Arcane ward: strong, 4 damage.'],
            // Ember Blast is arcane fire against a water enemy: always weak, and the
            // damage floor of 1 hides the Arcane ward reduction entirely.
            'emberBlast/high': [1, 'Ember Blast met High guard: weak, 1 damage.'],
            'emberBlast/side': [1, 'Ember Blast met Side guard: weak, 1 damage.'],
            'emberBlast/brace': [1, 'Ember Blast met Brace: weak, 1 damage.'],
            'emberBlast/ward': [1, 'Ember Blast met Arcane ward: weak, 1 damage.'],
        }
        const scenario = await battle()
        const observed: Record<string, [number, string]> = {}
        for (const attack of ['stab', 'chargeHigh', 'chargeSide', 'leap', 'emberBlast'] as const) {
            for (const guard of ['high', 'side', 'brace', 'ward'] as const) {
                await reset(scenario, 'attack', GUARD_SEED[guard])
                await scenario.dispatch('Ava', {
                    type: 'combat.attack',
                    subjects: subjectsOf(scenario),
                    data: { attack },
                })
                const combat = await scenario.combat()
                expect(combat?.lastGuard).toBe(guard)
                expect(combat?.enemyHp).toBe(11 - (combat?.lastDamage ?? 0))
                observed[`${attack}/${guard}`] = [combat?.lastDamage ?? -1, combat?.message ?? '']
            }
        }
        expect(observed).toEqual(expected)
    })

    test('a failed accuracy roll deals no damage and still passes the initiative', async () => {
        const scenario = await battle()
        await reset(scenario, 'attack', GUARD_SEED_MISS.high)
        await scenario.dispatch('Ava', {
            type: 'combat.attack',
            subjects: subjectsOf(scenario),
            data: { attack: 'stab' },
        })
        expect(await scenario.combat()).toMatchObject({
            lastAttack: 'stab',
            lastGuard: 'high',
            lastDamage: 0,
            enemyHp: 11,
            phase: 'defend',
            message: 'Quick stab missed!',
        })
        expect(await scenario.room()).toMatchObject({
            phase: 'combatDefend',
            message: 'Fen Slime prepares a counterattack. Choose a guard.',
        })
    })

    test('a debuff technique lowers a stat unless the ward stops it', async () => {
        const scenario = await battle()
        await reset(scenario, 'attack', GUARD_SEED.high)
        await scenario.dispatch('Ava', {
            type: 'combat.attack',
            subjects: subjectsOf(scenario),
            data: { attack: 'scorchArmor' },
        })
        expect(await scenario.combat()).toMatchObject({
            lastAttack: 'scorchArmor',
            lastGuard: 'high',
            lastDamage: 0,
            enemyHp: 11,
            enemyDefensePenalty: 1,
            phase: 'defend',
            message: "Scorch Armor lowered the enemy's defense.",
        })

        await reset(scenario, 'attack', GUARD_SEED.ward)
        await scenario.dispatch('Ava', {
            type: 'combat.attack',
            subjects: subjectsOf(scenario),
            data: { attack: 'scorchArmor' },
        })
        const warded = await scenario.combat()
        expect(warded?.message).toBe('Arcane ward nullified Scorch Armor.')
        expect(warded?.enemyDefensePenalty).toBeUndefined()
    })

    test('a technique outside the equipped grimoire is refused', async () => {
        const scenario = await battle()
        await reset(scenario, 'attack', GUARD_SEED.high)
        await expect(
            scenario.dispatch('Ava', {
                type: 'combat.attack',
                subjects: subjectsOf(scenario),
                data: { attack: 'tideNeedle' },
            }),
        ).rejects.toThrow(/Equip the grimoire containing that technique first/)
        expect((await scenario.combat())?.lastAttack).toBeUndefined()
    })

    test('every enemy attack against every hero guard deals its pinned damage', async () => {
        const expected: Record<string, [number, string]> = {
            'stab/high': [1, "Fen Slime's Quick stab met High guard: neutral, 1 damage."],
            'stab/side': [1, "Fen Slime's Quick stab met Side guard: neutral, 1 damage."],
            'stab/brace': [1, "Fen Slime's Quick stab met Brace: neutral, 1 damage."],
            'stab/ward': [2, "Fen Slime's Quick stab met Arcane ward: strong, 2 damage."],
            'chargeHigh/high': [1, "Fen Slime's High charge met High guard: weak, 1 damage."],
            'chargeHigh/side': [4, "Fen Slime's High charge met Side guard: strong, 4 damage."],
            'chargeHigh/brace': [2, "Fen Slime's High charge met Brace: neutral, 2 damage."],
            'chargeHigh/ward': [4, "Fen Slime's High charge met Arcane ward: strong, 4 damage."],
            'chargeSide/high': [2, "Fen Slime's Side rush met High guard: neutral, 2 damage."],
            'chargeSide/side': [1, "Fen Slime's Side rush met Side guard: weak, 1 damage."],
            'chargeSide/brace': [3, "Fen Slime's Side rush met Brace: strong, 3 damage."],
            'chargeSide/ward': [4, "Fen Slime's Side rush met Arcane ward: strong, 4 damage."],
            'leap/high': [4, "Fen Slime's Leaping strike met High guard: strong, 4 damage."],
            'leap/side': [2, "Fen Slime's Leaping strike met Side guard: neutral, 2 damage."],
            'leap/brace': [1, "Fen Slime's Leaping strike met Brace: weak, 1 damage."],
            'leap/ward': [4, "Fen Slime's Leaping strike met Arcane ward: strong, 4 damage."],
            'tideNeedle/high': [4, "Fen Slime's Tide Needle met High guard: strong, 4 damage."],
            'tideNeedle/side': [1, "Fen Slime's Tide Needle met Side guard: weak, 1 damage."],
            'tideNeedle/brace': [2, "Fen Slime's Tide Needle met Brace: neutral, 2 damage."],
            'tideNeedle/ward': [4, "Fen Slime's Tide Needle met Arcane ward: strong, 4 damage."],
            'undertow/high': [0, "Fen Slime's Undertow lowered Ava's agility."],
            'undertow/side': [0, "Fen Slime's Undertow lowered Ava's agility."],
            'undertow/brace': [0, "Fen Slime's Undertow lowered Ava's agility."],
            'undertow/ward': [0, "Ava's Arcane ward nullified Undertow."],
        }
        const scenario = await battle()
        const observed: Record<string, [number, string]> = {}
        for (const [enemyAttack, seed] of Object.entries(ENEMY_SEED)) {
            for (const guard of ['high', 'side', 'brace', 'ward'] as const) {
                await reset(scenario, 'defend', seed)
                await scenario.dispatch('Ava', {
                    type: 'combat.guard',
                    subjects: subjectsOf(scenario),
                    data: { guard },
                })
                const combat = await scenario.combat()
                expect(combat?.lastAttack).toBe(enemyAttack)
                expect(combat?.round).toBe(2)
                expect((await scenario.player(0)).hp).toBe(10 - (combat?.lastDamage ?? 0))
                expect((await scenario.room()).phase).toBe('combatAttack')
                observed[`${enemyAttack}/${guard}`] = [
                    combat?.lastDamage ?? -1,
                    combat?.message ?? '',
                ]
            }
        }
        expect(observed).toEqual(expected)
        expect((await scenario.combat())?.playerAgilityPenalty).toBeUndefined()
    })

    test('defeating the enemy pays the reward and passes the turn', async () => {
        const scenario = await battle()
        await reset(scenario, 'attack', GUARD_SEED.brace)
        const combatId = (await scenario.combat())?._id
        if (!combatId) throw new Error('expected a live combat')
        await scenario.t.run(async (ctx) => ctx.db.patch(combatId, { enemyHp: 4 }))
        await scenario.dispatch('Ava', {
            type: 'combat.attack',
            subjects: subjectsOf(scenario),
            data: { attack: 'chargeSide' },
        })
        expect(await scenario.combat()).toMatchObject({
            enemyHp: 0,
            lastDamage: 4,
            phase: 'resolved',
        })
        expect(await scenario.player(0)).toMatchObject({ gold: 16, hp: 10, position: 1 })
        const room = await scenario.room()
        expect(room).toMatchObject({
            phase: 'awaitingRoll',
            remainingMoves: 0,
            round: 1,
            activePlayerId: scenario.playerIds[1],
            message: 'Ava defeated Fen Slime and won 6 gold.',
        })
        expect(room.activeCombatId).toBeUndefined()
    })

    test('losing the battle heals the hero, costs three gold and sends them home', async () => {
        const scenario = await battle()
        await reset(scenario, 'defend', ENEMY_SEED.leap)
        await scenario.patchPlayer(0, { hp: 1, gold: 10 })
        await scenario.dispatch('Ava', {
            type: 'combat.guard',
            subjects: subjectsOf(scenario),
            data: { guard: 'brace' },
        })
        expect(await scenario.combat()).toMatchObject({
            lastDamage: 1,
            phase: 'resolved',
            round: 2,
        })
        const player = await scenario.player(0)
        expect(player).toMatchObject({ hp: 10, gold: 7, position: 0 })
        expect(player.previousPosition).toBeUndefined()
        expect(await scenario.room()).toMatchObject({
            phase: 'awaitingRoll',
            activePlayerId: scenario.playerIds[1],
            message: 'Ava fell to Fen Slime and awoke at Hearthkeep, losing 3 gold.',
        })
    })

    test('a defeated hero with little gold loses only what they carry', async () => {
        const scenario = await battle()
        await reset(scenario, 'defend', ENEMY_SEED.leap)
        await scenario.patchPlayer(0, { hp: 1, gold: 2 })
        await scenario.dispatch('Ava', {
            type: 'combat.guard',
            subjects: subjectsOf(scenario),
            data: { guard: 'brace' },
        })
        expect((await scenario.player(0)).gold).toBe(0)
        expect((await scenario.room()).message).toBe(
            'Ava fell to Fen Slime and awoke at Hearthkeep, losing 2 gold.',
        )
    })

    test('a combat choice made in the wrong phase is refused', async () => {
        const scenario = await battle()
        await reset(scenario, 'attack', GUARD_SEED.high)
        await expect(
            scenario.dispatch('Ava', {
                type: 'combat.guard',
                subjects: subjectsOf(scenario),
                data: { guard: 'high' },
            }),
        ).rejects.toThrow(/That combat choice is not available/)
        await reset(scenario, 'defend', ENEMY_SEED.stab)
        await expect(
            scenario.dispatch('Ava', {
                type: 'combat.attack',
                subjects: subjectsOf(scenario),
                data: { attack: 'stab' },
            }),
        ).rejects.toThrow(/That combat choice is not available/)
    })
})
