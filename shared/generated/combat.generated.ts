/** Generated from proofs/Mythroads/Game/Combat.lean. Do not edit by hand. */
import {
    type Game_Magic_Element as EngineElement,
    type Option as EngineOption,
    type Strike as EngineStrike,
    strikeDamage as engineStrikeDamage,
} from '../engine.system.ts'
import { type Element, MAGIC_TECHNIQUES, type MagicTechniqueId } from '../magic.system.ts'

export const PHYSICAL_ATTACKS = ['stab', 'chargeHigh', 'chargeSide', 'leap'] as const
export const GUARD_STANCES = ['high', 'side', 'brace', 'ward'] as const
export type PhysicalAttack = (typeof PHYSICAL_ATTACKS)[number]
export type GuardStance = (typeof GUARD_STANCES)[number]
export type CombatAttack = PhysicalAttack | MagicTechniqueId
export type Matchup = 'weak' | 'neutral' | 'strong'
export type BattleStats = {
    attack: number
    defense: number
    magic: number
    athletics: number
    agility: number
}

export const ATTACK_LABELS: Record<CombatAttack, string> = {
    stab: 'Quick stab',
    chargeHigh: 'High charge',
    chargeSide: 'Side rush',
    leap: 'Leaping strike',
    emberBlast: 'Ember Blast',
    scorchArmor: 'Scorch Armor',
    tideNeedle: 'Tide Needle',
    undertow: 'Undertow',
    galeBlade: 'Gale Blade',
    windShear: 'Wind Shear',
    stoneCrash: 'Stone Crash',
    calcify: 'Calcify',
}
export const GUARD_LABELS: Record<GuardStance, string> = {
    high: 'High guard',
    side: 'Side guard',
    brace: 'Brace',
    ward: 'Arcane ward',
}
const PHYSICAL_MATCHUPS: Record<PhysicalAttack, Record<GuardStance, Matchup>> = {
    stab: { high: 'neutral', side: 'neutral', brace: 'neutral', ward: 'strong' },
    chargeHigh: { high: 'weak', side: 'strong', brace: 'neutral', ward: 'strong' },
    chargeSide: { high: 'neutral', side: 'weak', brace: 'strong', ward: 'strong' },
    leap: { high: 'strong', side: 'neutral', brace: 'weak', ward: 'strong' },
}
export const isMagicTechnique = (attack: CombatAttack): attack is MagicTechniqueId =>
    attack in MAGIC_TECHNIQUES
export function physicalMatchup(attack: PhysicalAttack, guard: GuardStance) {
    return PHYSICAL_MATCHUPS[attack][guard]
}
export function strikeDamage(
    attack: CombatAttack,
    guard: GuardStance,
    attacker: BattleStats,
    defender: BattleStats,
    targetElement?: Element,
    wardPower = 0.35,
) {
    const strike: EngineStrike = isMagicTechnique(attack)
        ? { _: 'magic', technique: { _: attack } }
        : { _: 'physical', attack: { _: attack } }
    const target: EngineOption<EngineElement> = targetElement
        ? { _: 'some', val: { _: targetElement } }
        : { _: 'none' }
    const result = engineStrikeDamage(
        strike,
        { _: guard },
        attacker,
        defender,
        target,
        Math.round(wardPower * 100),
    )
    return { matchup: result.matchup._, accuracy: result.accuracy / 10000, damage: result.damage }
}
const ENEMIES = [
    {
        name: 'Mossback Boar',
        element: 'earth',
        hp: 14,
        attack: 3,
        defense: 3,
        magic: 1,
        athletics: 4,
        agility: 1,
        reward: 7,
    },
    {
        name: 'Fen Slime',
        element: 'water',
        hp: 11,
        attack: 2,
        defense: 2,
        magic: 3,
        athletics: 1,
        agility: 2,
        reward: 6,
    },
    {
        name: 'Ember Imp',
        element: 'fire',
        hp: 12,
        attack: 3,
        defense: 2,
        magic: 4,
        athletics: 2,
        agility: 4,
        reward: 8,
    },
    {
        name: 'Gale Wolf',
        element: 'wind',
        hp: 15,
        attack: 4,
        defense: 2,
        magic: 2,
        athletics: 4,
        agility: 5,
        reward: 9,
    },
] as const
export function enemyForSpace(spaceId: number) {
    return ENEMIES[spaceId % ENEMIES.length]
}
