import assert from 'node:assert/strict'
import test from 'node:test'
import { availableSteps, canTraverse } from '../../shared/board.system.ts'
import { physicalMatchup, spellMatchup, strikeDamage } from '../../shared/combat.system.ts'

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
    const blocked = strikeDamage('chargeHigh', 'high', 4, 'earth')
    const exposed = strikeDamage('chargeHigh', 'side', 4, 'earth')
    assert.ok(exposed.damage > blocked.damage)
    assert.equal(spellMatchup('fire', 'earth'), 'strong')
    assert.equal(spellMatchup('fire', 'water'), 'weak')
})
