import assert from 'node:assert/strict'
import { readdirSync, readFileSync } from 'node:fs'
import test from 'node:test'
import {
    canTraverse,
    getNode,
    previewRouteStep,
    reachableRoutes,
    WORLD,
} from '../../shared/board.system.ts'
import { directionalRoads } from '../../shared/controller-input.system.ts'
import { physicalMatchup, strikeDamage } from '../../shared/combat.system.ts'
import { equippedMagic, itemsForShop } from '../../shared/item.system.ts'
import { elementMatchup, MAGIC_LOADOUTS } from '../../shared/magic.system.ts'
import { isPersistentGameEvent } from '../../convex/events/policy.ts'

test('game state has one public mutation entry point', () => {
    const convexDirectory = new URL('../../convex/', import.meta.url)
    const registrations = readdirSync(convexDirectory)
        .filter((file) => file.endsWith('.ts'))
        .filter((file) =>
            /\bmutation\s*\(\s*\{/.test(readFileSync(new URL(file, convexDirectory), 'utf8')),
        )
    assert.deepEqual(registrations, ['game.ts'])
})

test('camera controls are ephemeral rather than durable game events', () => {
    const subjects = { roomId: 'room', playerId: 'player' }
    assert.equal(
        isPersistentGameEvent({ type: 'camera.move', subjects, data: { direction: 'up' } }),
        false,
    )
    assert.equal(isPersistentGameEvent({ type: 'movement.roll', subjects, data: {} }), true)
})

test('one-way roads only permit travel in their declared direction', () => {
    assert.equal(canTraverse(10, 14), true)
    assert.equal(canTraverse(14, 10), false)
    assert.equal(canTraverse(7, 8), true)
    assert.equal(canTraverse(8, 7), true)
})

test('route preview refunds immediate bidirectional backtracking', () => {
    const forward = previewRouteStep(0, [], 1, 4)
    assert.deepEqual(forward, [1])
    assert.deepEqual(previewRouteStep(0, forward, 0, 4), [])
})

test('route preview cannot reverse a one-way road', () => {
    assert.deepEqual(previewRouteStep(10, [], 14, 4), [14])
    assert.equal(previewRouteStep(10, [14], 10, 4), null)
})

test('the world defines a healing castle and a river bridge', () => {
    assert.equal(getNode(0).kind, 'castle')
    assert.ok(WORLD.terrain.some((feature) => feature.kind === 'hill'))
    assert.ok(WORLD.terrain.some((feature) => feature.kind === 'river'))
    assert.ok(WORLD.roads.some((road) => road.bridge))
})

test('destination mode exposes exact-roll endpoints and adjacent roads', () => {
    const routes = reachableRoutes(0, undefined, 5)
    assert.ok(routes.length > 1)
    assert.ok(routes.every((route) => route.path.length === 5))
    const directions = directionalRoads(0)
    assert.ok(Object.keys(directions).length > 0)
})

test('road segments only cross when one of them is a bridge', () => {
    const segments = WORLD.roads.flatMap((road) => {
        const points = [getNode(road.from), ...(road.via ?? []), getNode(road.to)]
        return points.slice(1).map((to, index) => ({ road, from: points[index], to }))
    })
    const orientation = (a, b, c) => (b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x)
    const crosses = (first, second) =>
        orientation(first.from, first.to, second.from) *
            orientation(first.from, first.to, second.to) <
            0 &&
        orientation(second.from, second.to, first.from) *
            orientation(second.from, second.to, first.to) <
            0
    for (let left = 0; left < segments.length; left += 1) {
        for (let right = left + 1; right < segments.length; right += 1) {
            const a = segments[left]
            const b = segments[right]
            if (a.road.id === b.road.id || a.road.bridge || b.road.bridge) continue
            assert.equal(crosses(a, b), false, `${a.road.id} crosses ${b.road.id}`)
        }
    }
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
    assert.equal(elementMatchup('fire', 'earth'), 'strong')
    assert.equal(elementMatchup('fire', 'water'), 'weak')
})

test('arcane ward is strong against pure magic and exposed to physical attacks', () => {
    const attacker = { attack: 4, defense: 2, magic: 4, athletics: 3, agility: 3 }
    const defender = { attack: 2, defense: 3, magic: 2, athletics: 2, agility: 2 }
    const open = strikeDamage('emberBlast', 'high', attacker, defender, 'earth')
    const warded = strikeDamage('emberBlast', 'ward', attacker, defender, 'earth')
    const physical = strikeDamage('chargeHigh', 'ward', attacker, defender, 'earth')
    assert.ok(warded.damage < open.damage)
    assert.equal(physical.matchup, 'strong')
})

test('every grimoire grants exactly two battle actions', () => {
    for (const actions of Object.values(MAGIC_LOADOUTS)) assert.equal(actions.length, 2)
    const loadout = equippedMagic([
        { itemId: 'tide_grimoire', equippedSlot: 'offensiveMagic' },
        { itemId: 'aegis_script', equippedSlot: 'defensiveMagic' },
    ])
    assert.deepEqual(loadout.actions, ['tideNeedle', 'undertow'])
    assert.equal(loadout.wardPower, 0.35)
    assert.ok(itemsForShop('magic').some((item) => item.spell === 'earth'))
})

test('physical-magic techniques use Wucht Stich and Hieb guard matchups', () => {
    const attacker = { attack: 2, defense: 2, magic: 5, athletics: 2, agility: 3 }
    const defender = { attack: 2, defense: 3, magic: 8, athletics: 2, agility: 3 }
    assert.equal(strikeDamage('stoneCrash', 'side', attacker, defender).matchup, 'strong')
    assert.equal(strikeDamage('tideNeedle', 'side', attacker, defender).matchup, 'weak')
    assert.equal(strikeDamage('galeBlade', 'brace', attacker, defender).matchup, 'strong')
})
