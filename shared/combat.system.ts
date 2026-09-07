export const PHYSICAL_ATTACKS = ['stab', 'chargeHigh', 'chargeSide', 'leap'] as const
export const GUARD_STANCES = ['high', 'side', 'brace', 'ward'] as const
export const MAGIC_SPELLS = ['fire', 'water', 'wind', 'earth'] as const
export const ELEMENTS = ['fire', 'water', 'wind', 'earth'] as const

export type PhysicalAttack = (typeof PHYSICAL_ATTACKS)[number]
export type GuardStance = (typeof GUARD_STANCES)[number]
export type MagicSpell = (typeof MAGIC_SPELLS)[number]
export type Element = (typeof ELEMENTS)[number]
export type CombatAttack = PhysicalAttack | MagicSpell
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
    fire: 'Ember',
    water: 'Tide',
    wind: 'Gale',
    earth: 'Stonebind',
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

const SPELL_STRENGTH: Record<MagicSpell, { strong: Element; weak: Element }> = {
    fire: { strong: 'earth', weak: 'water' },
    water: { strong: 'fire', weak: 'wind' },
    wind: { strong: 'water', weak: 'earth' },
    earth: { strong: 'wind', weak: 'fire' },
}

const MULTIPLIER: Record<Matchup, number> = { weak: 0.55, neutral: 1, strong: 1.65 }
const POWER: Record<CombatAttack, number> = {
    stab: 1.15,
    chargeHigh: 1.45,
    chargeSide: 1.45,
    leap: 1.45,
    fire: 1.35,
    water: 1.25,
    wind: 1.2,
    earth: 1.3,
}

export const isMagicSpell = (attack: CombatAttack): attack is MagicSpell =>
    MAGIC_SPELLS.includes(attack as MagicSpell)

export function physicalMatchup(attack: PhysicalAttack, guard: GuardStance) {
    return PHYSICAL_MATCHUPS[attack][guard]
}

export function spellMatchup(spell: MagicSpell, element?: Element): Matchup {
    if (!element) return 'neutral'
    if (SPELL_STRENGTH[spell].strong === element) return 'strong'
    if (SPELL_STRENGTH[spell].weak === element) return 'weak'
    return 'neutral'
}

export function strikeDamage(
    attack: CombatAttack,
    guard: GuardStance,
    attacker: BattleStats,
    defender: BattleStats,
    targetElement?: Element,
    wardPower = 0.35,
) {
    const magical = isMagicSpell(attack)
    const matchup = magical ? spellMatchup(attack, targetElement) : physicalMatchup(attack, guard)
    const techniquePower = attack === 'stab' || magical ? 0 : attacker.athletics * 0.35
    const attackValue = magical ? attacker.magic : attacker.attack
    const resistance = magical ? defender.magic * 0.55 : defender.defense * 0.55
    const brace = !magical && guard === 'brace' ? defender.athletics * 0.25 : 0
    const ward = magical && guard === 'ward' ? wardPower : 1
    const accuracy = magical
        ? 1
        : Math.max(0.5, Math.min(0.98, 0.75 + (attacker.agility - defender.agility) * 0.04))
    return {
        matchup,
        accuracy,
        damage: Math.max(
            1,
            Math.round(
                (attackValue * POWER[attack] + techniquePower - resistance - brace) *
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
