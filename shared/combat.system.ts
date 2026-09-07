import {
    elementMatchup,
    MAGIC_TECHNIQUES,
    type Element,
    type ImpactType,
    type MagicTechniqueId,
} from './magic.system.ts'

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

const MULTIPLIER: Record<Matchup, number> = { weak: 0.55, neutral: 1, strong: 1.65 }
const POWER: Record<PhysicalAttack, number> = {
    stab: 1.15,
    chargeHigh: 1.45,
    chargeSide: 1.45,
    leap: 1.45,
}

export const isMagicTechnique = (attack: CombatAttack): attack is MagicTechniqueId =>
    attack in MAGIC_TECHNIQUES

export function physicalMatchup(attack: PhysicalAttack, guard: GuardStance) {
    return PHYSICAL_MATCHUPS[attack][guard]
}

const IMPACT_MATCHUPS: Record<ImpactType, Record<GuardStance, Matchup>> = {
    wucht: { high: 'neutral', side: 'strong', brace: 'weak', ward: 'strong' },
    stich: { high: 'strong', side: 'weak', brace: 'neutral', ward: 'strong' },
    hieb: { high: 'weak', side: 'neutral', brace: 'strong', ward: 'strong' },
}

export function strikeDamage(
    attack: CombatAttack,
    guard: GuardStance,
    attacker: BattleStats,
    defender: BattleStats,
    targetElement?: Element,
    wardPower = 0.35,
) {
    const technique = isMagicTechnique(attack) ? MAGIC_TECHNIQUES[attack] : undefined
    const arcane = technique?.delivery === 'arcane'
    const impact =
        technique && ['wucht', 'stich', 'hieb'].includes(technique.delivery)
            ? (technique.delivery as ImpactType)
            : undefined
    const matchup = arcane
        ? elementMatchup(technique.element, targetElement)
        : impact
          ? IMPACT_MATCHUPS[impact][guard]
          : physicalMatchup(attack as PhysicalAttack, guard)
    const physical = !arcane
    const techniquePower = technique ? 0 : attack === 'stab' ? 0 : attacker.athletics * 0.35
    const attackValue = technique ? attacker.magic : attacker.attack
    const resistance = arcane ? defender.magic * 0.55 : defender.defense * 0.55
    const brace = physical && guard === 'brace' ? defender.athletics * 0.25 : 0
    const ward = arcane && guard === 'ward' ? wardPower : 1
    const accuracy = arcane
        ? 1
        : Math.max(0.5, Math.min(0.98, 0.75 + (attacker.agility - defender.agility) * 0.04))
    const power = technique?.power ?? POWER[attack as PhysicalAttack]
    return {
        matchup,
        accuracy,
        damage: Math.max(
            1,
            Math.round(
                (attackValue * power + techniquePower - resistance - brace) *
                    MULTIPLIER[matchup] *
                    ward,
            ),
        ),
    }
}

export function enemyForSpace(spaceId: number) {
    const enemies = [
        {
            name: 'Mossback Boar',
            element: 'earth' as const,
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
            element: 'water' as const,
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
            element: 'fire' as const,
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
            element: 'wind' as const,
            hp: 15,
            attack: 4,
            defense: 2,
            magic: 2,
            athletics: 4,
            agility: 5,
            reward: 9,
        },
    ]
    return enemies[spaceId % enemies.length]
}
