export const ELEMENTS = ['fire', 'water', 'wind', 'earth'] as const
export type Element = (typeof ELEMENTS)[number]
export type ImpactType = 'wucht' | 'stich' | 'hieb'
export type DebuffStat = 'defense' | 'magic' | 'athletics' | 'agility'

export const MAGIC_TECHNIQUE_IDS = [
    'emberBlast',
    'scorchArmor',
    'tideNeedle',
    'undertow',
    'galeBlade',
    'windShear',
    'stoneCrash',
    'calcify',
] as const

export type MagicTechniqueId = (typeof MAGIC_TECHNIQUE_IDS)[number]
export type MagicTechnique = {
    id: MagicTechniqueId
    label: string
    element: Element
    delivery: 'arcane' | ImpactType | 'debuff'
    power: number
    debuff?: { stat: DebuffStat; amount: number }
    description: string
}

export const MAGIC_TECHNIQUES: Record<MagicTechniqueId, MagicTechnique> = {
    emberBlast: {
        id: 'emberBlast',
        label: 'Ember Blast',
        element: 'fire',
        delivery: 'arcane',
        power: 1.35,
        description: 'Pure magic damage. Arcane Ward is its direct counter.',
    },
    scorchArmor: {
        id: 'scorchArmor',
        label: 'Scorch Armor',
        element: 'fire',
        delivery: 'debuff',
        power: 0,
        debuff: { stat: 'defense', amount: 1 },
        description: 'Lower enemy Defense for this battle.',
    },
    tideNeedle: {
        id: 'tideNeedle',
        label: 'Tide Needle',
        element: 'water',
        delivery: 'stich',
        power: 1.25,
        description: 'Magic-powered Stich damage checked against physical guarding.',
    },
    undertow: {
        id: 'undertow',
        label: 'Undertow',
        element: 'water',
        delivery: 'debuff',
        power: 0,
        debuff: { stat: 'agility', amount: 1 },
        description: 'Lower enemy Agility for this battle.',
    },
    galeBlade: {
        id: 'galeBlade',
        label: 'Gale Blade',
        element: 'wind',
        delivery: 'hieb',
        power: 1.2,
        description: 'Magic-powered Hieb damage checked against physical guarding.',
    },
    windShear: {
        id: 'windShear',
        label: 'Wind Shear',
        element: 'wind',
        delivery: 'debuff',
        power: 0,
        debuff: { stat: 'athletics', amount: 1 },
        description: 'Lower enemy Athletics for this battle.',
    },
    stoneCrash: {
        id: 'stoneCrash',
        label: 'Stone Crash',
        element: 'earth',
        delivery: 'wucht',
        power: 1.3,
        description: 'Magic-powered Wucht damage checked against physical guarding.',
    },
    calcify: {
        id: 'calcify',
        label: 'Calcify',
        element: 'earth',
        delivery: 'debuff',
        power: 0,
        debuff: { stat: 'magic', amount: 1 },
        description: 'Lower enemy Magic for this battle.',
    },
}

export const MAGIC_LOADOUTS: Record<Element, readonly [MagicTechniqueId, MagicTechniqueId]> = {
    fire: ['emberBlast', 'scorchArmor'],
    water: ['tideNeedle', 'undertow'],
    wind: ['galeBlade', 'windShear'],
    earth: ['stoneCrash', 'calcify'],
}

const ELEMENT_EDGE: Record<Element, { strong: Element; weak: Element }> = {
    fire: { strong: 'earth', weak: 'water' },
    water: { strong: 'fire', weak: 'wind' },
    wind: { strong: 'water', weak: 'earth' },
    earth: { strong: 'wind', weak: 'fire' },
}

export function elementMatchup(element: Element, target?: Element) {
    if (!target) return 'neutral' as const
    if (ELEMENT_EDGE[element].strong === target) return 'strong' as const
    if (ELEMENT_EDGE[element].weak === target) return 'weak' as const
    return 'neutral' as const
}
