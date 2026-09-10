/** Generated from proofs/Mythroads/Backend/Aggregate/Enums.lean. Do not edit by hand. */
import type {
    Direction,
    Game_Combat_Guard,
    Game_Inventory_EquipmentSlot,
    Game_Inventory_ShopKind,
    Game_Magic_Element,
    Strike,
} from '../../../shared/engine.system'

export function equipmentSlotOf(label: string): Game_Inventory_EquipmentSlot {
    if (label === 'helmet') {
        return { _: 'helmet' }
    }
    if (label === 'body') {
        return { _: 'body' }
    }
    if (label === 'gloves') {
        return { _: 'gloves' }
    }
    if (label === 'boots') {
        return { _: 'boots' }
    }
    if (label === 'cape') {
        return { _: 'cape' }
    }
    if (label === 'amulet') {
        return { _: 'amulet' }
    }
    if (label === 'ringLeft') {
        return { _: 'ringLeft' }
    }
    if (label === 'ringRight') {
        return { _: 'ringRight' }
    }
    if (label === 'offensiveMagic') {
        return { _: 'offensiveMagic' }
    }
    if (label === 'defensiveMagic') {
        return { _: 'defensiveMagic' }
    }
    return { _: 'weapon' }
}

export function shopKindOf(label: string): Game_Inventory_ShopKind {
    if (label === 'jeweller') {
        return { _: 'jeweller' }
    }
    if (label === 'weapons') {
        return { _: 'weapons' }
    }
    if (label === 'items') {
        return { _: 'items' }
    }
    if (label === 'magic') {
        return { _: 'magic' }
    }
    return { _: 'armoury' }
}

export function elementOf(label: string): Game_Magic_Element {
    if (label === 'water') {
        return { _: 'water' }
    }
    if (label === 'wind') {
        return { _: 'wind' }
    }
    if (label === 'earth') {
        return { _: 'earth' }
    }
    return { _: 'fire' }
}

export function guardOf(label: string): Game_Combat_Guard {
    if (label === 'side') {
        return { _: 'side' }
    }
    if (label === 'brace') {
        return { _: 'brace' }
    }
    if (label === 'ward') {
        return { _: 'ward' }
    }
    return { _: 'high' }
}

export function directionOf(direction: string): Direction {
    if (direction === 'down') {
        return { _: 'down' }
    }
    if (direction === 'left') {
        return { _: 'left' }
    }
    if (direction === 'right') {
        return { _: 'right' }
    }
    return { _: 'up' }
}

export function strikeOf(attack: string): Strike {
    if (attack === 'chargeHigh') {
        return { _: 'physical', attack: { _: 'chargeHigh' } }
    }
    if (attack === 'chargeSide') {
        return { _: 'physical', attack: { _: 'chargeSide' } }
    }
    if (attack === 'leap') {
        return { _: 'physical', attack: { _: 'leap' } }
    }
    if (attack === 'emberBlast') {
        return { _: 'magic', technique: { _: 'emberBlast' } }
    }
    if (attack === 'scorchArmor') {
        return { _: 'magic', technique: { _: 'scorchArmor' } }
    }
    if (attack === 'tideNeedle') {
        return { _: 'magic', technique: { _: 'tideNeedle' } }
    }
    if (attack === 'undertow') {
        return { _: 'magic', technique: { _: 'undertow' } }
    }
    if (attack === 'galeBlade') {
        return { _: 'magic', technique: { _: 'galeBlade' } }
    }
    if (attack === 'windShear') {
        return { _: 'magic', technique: { _: 'windShear' } }
    }
    if (attack === 'stoneCrash') {
        return { _: 'magic', technique: { _: 'stoneCrash' } }
    }
    if (attack === 'calcify') {
        return { _: 'magic', technique: { _: 'calcify' } }
    }
    return { _: 'physical', attack: { _: 'stab' } }
}
