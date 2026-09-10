import type { Id } from '../../convex/_generated/dataModel'
import type { GameEvent } from '../../convex/events/validators'
import { reachableRoutes } from '../../shared/board.system'
import { getItem, itemsForShop } from '../../shared/item.system'
import type { Scenario } from './scenario.helper'

/**
 * A deterministic bot that drives a whole game through `api.game.dispatch`, and the
 * symbolic form used to store its trace as a fixture. Ids differ between runs only in
 * spelling, so they are recorded as `$room`, `$p0` … `$p3`, `$encounter` and `$lastItem`.
 */
export type TraceStep = {
    actor: string
    event: unknown
    resultKind: string
    stateDigest: string
}

const ATTACKS = ['stab', 'chargeHigh', 'chargeSide', 'leap', 'emberBlast', 'scorchArmor'] as const
const GUARDS = ['high', 'side', 'brace', 'ward'] as const
const CAMERA_STEPS = [8, 9, 10]
const CANCEL_STEPS = [32]

function token(scenario: Scenario, id: string): string {
    if (id === scenario.roomId) return '$room'
    const index = scenario.playerIds.indexOf(id as Id<'players'>)
    if (index >= 0) return `$p${index}`
    return '$encounter'
}

export async function symbolize(scenario: Scenario, event: GameEvent): Promise<unknown> {
    const raw = event.subjects as Record<string, string>
    const subjects: Record<string, unknown> = {}
    for (const [key, value] of Object.entries(raw)) {
        subjects[key] =
            key === 'playerItemId'
                ? `$item${await itemIndex(scenario, raw.playerId, value)}`
                : token(scenario, value)
    }
    return { type: event.type, subjects, data: event.data }
}

async function itemIndex(scenario: Scenario, playerId: string, playerItemId: string) {
    const index = scenario.playerIds.indexOf(playerId as Id<'players'>)
    const items = await scenario.items(index)
    return items.findIndex((item) => item._id === playerItemId)
}

export async function materialize(scenario: Scenario, stored: unknown): Promise<GameEvent> {
    const raw = stored as { type: string; subjects: Record<string, string>; data: unknown }
    const subjects: Record<string, unknown> = {}
    for (const [key, value] of Object.entries(raw.subjects)) {
        if (value === '$room') subjects[key] = scenario.roomId
        else if (value.startsWith('$p')) subjects[key] = scenario.playerIds[Number(value.slice(2))]
        else if (value === '$encounter') subjects[key] = (await scenario.room()).activeEncounterId
        else if (value.startsWith('$item'))
            subjects[key] = await itemAt(scenario, raw.subjects.playerId, Number(value.slice(5)))
        else subjects[key] = value
    }
    return { type: raw.type, subjects, data: raw.data } as GameEvent
}

async function itemAt(scenario: Scenario, playerToken: string, position: number) {
    const items = await scenario.items(Number((playerToken ?? '$p0').slice(2)))
    return items[position]._id
}

/** A compact, id-free description of everything the tests care about. */
export async function digest(scenario: Scenario): Promise<string> {
    const room = await scenario.room()
    const players = await scenario.players()
    const combat = await scenario.combat()
    const encounter = await scenario.encounter()
    const selection = await scenario.selection()
    const camera = await scenario.camera()
    const active = players.findIndex((player) => player._id === room.activePlayerId)
    const parts = [
        `room=${room.status}/${room.phase}/r${room.round}/m${room.remainingMoves}`,
        `roll=${(room.lastRoll ?? []).join('-') || '-'}`,
        `rng=${room.rngState}#${room.rngCounter}`,
        `shop=${room.shopKind ?? '-'}`,
        `active=p${active}`,
        players
            .map(
                (player) =>
                    `${player.name}@${player.position}<${player.previousPosition ?? '-'}` +
                    `/hp${player.hp}/g${player.gold}`,
            )
            .join(','),
        combat
            ? `combat=${combat.enemyName}:${combat.enemyHp}/${combat.phase}/r${combat.round}` +
              `/${combat.lastAttack ?? '-'}:${combat.lastGuard ?? '-'}:${combat.lastDamage ?? '-'}`
            : 'combat=-',
        encounter ? `encounter=${encounter.outcomeId}:${encounter.status}` : 'encounter=-',
        selection
            ? `selection=${selection.destination}:[${(selection.path ?? []).join('-')}]`
            : 'selection=-',
        camera
            ? `camera=${camera.mode}:${camera.targetX.toFixed(2)}:${camera.targetZ.toFixed(2)}:${camera.distance}`
            : 'camera=-',
    ]
    return parts.join('|')
}

type BotState = { route: number; combatChoice: number; shopStage: number }

/** Decide the single next command for whoever is on turn. */
async function nextEvent(scenario: Scenario, state: BotState, stepIndex: number) {
    const room = await scenario.room()
    const index = scenario.playerIds.indexOf(room.activePlayerId ?? scenario.playerIds[0])
    const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[index] }
    const actor = scenario.names[index]
    const player = await scenario.player(index)
    if (CAMERA_STEPS.includes(stepIndex)) {
        const camera = await scenario.camera()
        const event: GameEvent = camera
            ? stepIndex % 2 === 0
                ? { type: 'camera.move', subjects, data: { direction: 'left' } }
                : { type: 'camera.zoom', subjects, data: { delta: 1 } }
            : { type: 'camera.toggle', subjects, data: {} }
        return { actor, event }
    }
    const phase = room.phase ?? (room.remainingMoves > 0 ? 'moving' : 'awaitingRoll')
    if (phase === 'awaitingRoll') {
        state.route += 1
        state.shopStage = 0
        return { actor, event: { type: 'movement.roll', subjects, data: {} } as GameEvent }
    }
    if (phase === 'moving') {
        const selection = await scenario.selection()
        if (!selection) {
            return {
                actor,
                event: {
                    type: 'movement.select',
                    subjects,
                    data: { destination: player.position },
                } as GameEvent,
            }
        }
        const path = selection.path ?? []
        if (CANCEL_STEPS.includes(stepIndex) && path.length > 0) {
            return { actor, event: { type: 'movement.cancel', subjects, data: {} } as GameEvent }
        }
        if (path.length < room.remainingMoves) {
            const routes = reachableRoutes(
                player.position,
                player.previousPosition,
                room.remainingMoves,
            )
            const route = routes[state.route % routes.length]
            return {
                actor,
                event: {
                    type: 'movement.select',
                    subjects,
                    data: { destination: route.path[path.length] },
                } as GameEvent,
            }
        }
        return {
            actor,
            event: {
                type: 'movement.step',
                subjects,
                data: { destination: selection.destination },
            } as GameEvent,
        }
    }
    if (phase === 'revealingEncounter') {
        await scenario.ripenEncounter()
        const encounterId = room.activeEncounterId
        if (!encounterId) throw new Error('expected a live encounter')
        return {
            actor,
            event: {
                type: 'encounter.resolve',
                subjects: { ...subjects, encounterId },
                data: {},
            } as GameEvent,
        }
    }
    if (phase === 'shopping') {
        return shopEvent(scenario, state, index, actor, subjects, player.gold, room.shopKind)
    }
    if (phase === 'combatAttack') {
        state.combatChoice += 1
        const attack = ATTACKS[state.combatChoice % ATTACKS.length]
        return { actor, event: { type: 'combat.attack', subjects, data: { attack } } as GameEvent }
    }
    state.combatChoice += 1
    const guard = GUARDS[state.combatChoice % GUARDS.length]
    return { actor, event: { type: 'combat.guard', subjects, data: { guard } } as GameEvent }
}

async function shopEvent(
    scenario: Scenario,
    state: BotState,
    index: number,
    actor: string,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    gold: number,
    shopKind: 'armoury' | 'jeweller' | 'weapons' | 'items' | 'magic' | undefined,
) {
    const budget = shopKind ? itemsForShop(shopKind).filter((item) => item.price <= gold) : []
    const equippable = budget.filter((item) => item.slots.length)
    const affordable = equippable.length ? equippable : budget
    if (state.shopStage === 0 && affordable.length) {
        state.shopStage = 1
        const item = affordable[state.route % affordable.length]
        return {
            actor,
            event: { type: 'shop.buy', subjects, data: { itemId: item.id } } as GameEvent,
        }
    }
    if (state.shopStage === 1) {
        state.shopStage = 2
        const items = await scenario.items(index)
        const wearable = items
            .map((owned) => ({ owned, slots: getItem(owned.itemId)?.slots ?? [] }))
            .filter((candidate) => candidate.slots.length)
            .at(-1)
        if (wearable) {
            return {
                actor,
                event: {
                    type: 'inventory.equip',
                    subjects: { playerId: subjects.playerId, playerItemId: wearable.owned._id },
                    data: { slot: wearable.slots[0] },
                } as GameEvent,
            }
        }
    }
    state.shopStage = 2
    return { actor, event: { type: 'shop.leave', subjects, data: {} } as GameEvent }
}

/** Play until the round limit or the step budget is reached, recording every dispatch. */
export async function playThrough(
    scenario: Scenario,
    limits: { steps: number; rounds: number },
): Promise<TraceStep[]> {
    const state: BotState = { route: 0, combatChoice: 0, shopStage: 0 }
    const trace: TraceStep[] = []
    while (trace.length < limits.steps) {
        if ((await scenario.room()).round > limits.rounds) break
        const { actor, event } = await nextEvent(scenario, state, trace.length)
        const result = await scenario.dispatch(actor, event)
        trace.push({
            actor,
            event: await symbolize(scenario, event),
            resultKind: result.kind,
            stateDigest: await digest(scenario),
        })
    }
    return trace
}
