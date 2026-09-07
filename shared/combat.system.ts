export const PHYSICAL_ATTACKS = ['stab', 'chargeHigh', 'chargeSide', 'leap'] as const
export const GUARD_STANCES = ['high', 'side', 'brace'] as const
export const MAGIC_SPELLS = ['fire', 'water', 'wind'] as const
export const ELEMENTS = ['fire', 'water', 'wind', 'earth'] as const

export type PhysicalAttack = (typeof PHYSICAL_ATTACKS)[number]
export type GuardStance = (typeof GUARD_STANCES)[number]
export type MagicSpell = (typeof MAGIC_SPELLS)[number]
export type Element = (typeof ELEMENTS)[number]
export type CombatAttack = PhysicalAttack | MagicSpell
export type Matchup = 'weak' | 'neutral' | 'strong'

export const ATTACK_LABELS: Record<CombatAttack, string> = {
    stab: 'Quick stab',
    chargeHigh: 'High charge',
    chargeSide: 'Side rush',
    leap: 'Leaping strike',
    fire: 'Ember',
    water: 'Tide',
    wind: 'Gale',
}

export const GUARD_LABELS: Record<GuardStance, string> = {
    high: 'High guard',
    side: 'Side guard',
    brace: 'Brace',
}

const PHYSICAL_MATCHUPS: Record<PhysicalAttack, Record<GuardStance, Matchup>> = {
    stab: { high: 'neutral', side: 'neutral', brace: 'neutral' },
    chargeHigh: { high: 'weak', side: 'strong', brace: 'neutral' },
    chargeSide: { high: 'neutral', side: 'weak', brace: 'strong' },
    leap: { high: 'strong', side: 'neutral', brace: 'weak' },
}

const SPELL_STRENGTH: Record<MagicSpell, { strong: Element; weak: Element }> = {
    fire: { strong: 'earth', weak: 'water' },
    water: { strong: 'fire', weak: 'wind' },
    wind: { strong: 'water', weak: 'earth' },
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
}

export const isMagicSpell = (attack: CombatAttack): attack is MagicSpell =>
    MAGIC_SPELLS.includes(attack as MagicSpell)

export function physicalMatchup(attack: PhysicalAttack, guard: GuardStance) {
    return PHYSICAL_MATCHUPS[attack][guard]
}

export function spellMatchup(spell: MagicSpell, element: Element): Matchup {
    if (SPELL_STRENGTH[spell].strong === element) return 'strong'
    if (SPELL_STRENGTH[spell].weak === element) return 'weak'
    return 'neutral'
}

export function strikeDamage(
    attack: CombatAttack,
    guard: GuardStance,
    attackStat: number,
    enemyElement: Element,
) {
    const matchup = isMagicSpell(attack)
        ? spellMatchup(attack, enemyElement)
        : physicalMatchup(attack, guard)
    const bracePenalty = isMagicSpell(attack) && guard === 'brace' ? 0.75 : 1
    return {
        matchup,
        damage: Math.max(
            1,
            Math.round(attackStat * POWER[attack] * MULTIPLIER[matchup] * bracePenalty),
        ),
    }
}

export function enemyForSpace(spaceId: number) {
    const enemies = [
        { name: 'Mossback Boar', element: 'earth' as const, hp: 10, attack: 2, reward: 7 },
        { name: 'Fen Slime', element: 'water' as const, hp: 8, attack: 2, reward: 6 },
        { name: 'Ember Imp', element: 'fire' as const, hp: 9, attack: 3, reward: 8 },
        { name: 'Gale Wolf', element: 'wind' as const, hp: 11, attack: 3, reward: 9 },
    ]
    return enemies[spaceId % enemies.length]
}
