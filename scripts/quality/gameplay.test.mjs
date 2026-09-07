import assert from 'node:assert/strict'
import test from 'node:test'
import { availableSteps, canTraverse } from '../../shared/board.system.ts'
import { physicalMatchup, spellMatchup, strikeDamage } from '../../shared/combat.system.ts'
import { equippedMagic, itemsForShop } from '../../shared/item.system.ts'

test('one-way roads only permit travel in their declared direction', () => {
    assert.equal(canTraverse(4, 18), true)
    assert.equal(canTraverse(18, 4), false)
    assert.equal(canTraverse(7, 14), true)
    assert.equal(canTraverse(14, 7), true)
})

test('movement excludes the previous field when another exit exists', () => {
    assert.equal(availableSteps(4, 3).includes(3), false)
    assert.equal(availableSteps(4, 3).includes(18), true)
})

test('each committed charge has a strong neutral and weak guard matchup', () => {
    for (const attack of ['chargeHigh', 'chargeSide', 'leap']) {
        const matchups = ['high', 'side', 'brace'].map((guard) => physicalMatchup(attack, guard))
        assert.deepEqual(new Set(matchups), new Set(['weak', 'neutral', 'strong']))
    }
})

test('physical and elemental advantages materially change damage', () => {
    const attacker = { attack: 4, defense: 2, magic: 4, athletics: 3, agility: 3 }
    const defender = { attack: 2, defense: 3, magic: 2, athletics: 2, agility: 2 }
    const blocked = strikeDamage('chargeHigh', 'high', attacker, defender, 'earth')
    const exposed = strikeDamage('chargeHigh', 'side', attacker, defender, 'earth')
    assert.ok(exposed.damage > blocked.damage)
    assert.equal(spellMatchup('fire', 'earth'), 'strong')
    assert.equal(spellMatchup('fire', 'water'), 'weak')
})

test('arcane ward is strong against magic and exposed to physical attacks', () => {
    const attacker = { attack: 4, defense: 2, magic: 4, athletics: 3, agility: 3 }
    const defender = { attack: 2, defense: 3, magic: 2, athletics: 2, agility: 2 }
    const open = strikeDamage('fire', 'high', attacker, defender, 'earth')
    const warded = strikeDamage('fire', 'ward', attacker, defender, 'earth')
    const physical = strikeDamage('chargeHigh', 'ward', attacker, defender, 'earth')
    assert.ok(warded.damage < open.damage)
    assert.equal(physical.matchup, 'strong')
})

test('battle and defensive magic come from the equipped loadout', () => {
    const loadout = equippedMagic([
        { itemId: 'tide_grimoire', equippedSlot: 'offensiveMagic' },
        { itemId: 'aegis_script', equippedSlot: 'defensiveMagic' },
    ])
    assert.equal(loadout.spell, 'water')
    assert.equal(loadout.wardPower, 0.35)
    assert.ok(itemsForShop('magic').some((item) => item.spell === 'earth'))
})
