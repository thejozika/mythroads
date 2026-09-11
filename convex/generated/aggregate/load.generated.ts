/** Generated from proofs/Mythroads/Backend/Aggregate/Load.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import type {
    Camera,
    CombatState,
    EncounterState,
    Game_Encounter_Kind,
    Owned,
    Phase,
    PlayerState,
    Selection,
    State,
} from '../../../shared/engine.system'
import type { Doc, Id } from '../../_generated/dataModel'
import type { MutationCtx } from '../../_generated/server'
import { normalizeSeed } from '../random.generated'
import { elementOf, equipmentSlotOf, guardOf, shopKindOf } from './enums.generated'

function ownedFrom(row: Doc<'playerItems'>): Owned {
    return {
        rowId: row._id,
        itemId: row.itemId,
        equippedSlot:
            row.equippedSlot === undefined
                ? { _: 'none' }
                : { _: 'some', val: equipmentSlotOf(row.equippedSlot) },
    }
}

function heroFrom(row: Doc<'players'>, items: Doc<'playerItems'>[]): PlayerState {
    return {
        id: row._id,
        owner: row.authId ?? '',
        name: row.name,
        color: row.color,
        position: row.position,
        previousPosition:
            row.previousPosition === undefined
                ? { _: 'none' }
                : { _: 'some', val: row.previousPosition },
        gold: row.gold,
        hp: row.hp,
        maxHp: row.maxHp,
        attack: row.attack,
        defense: row.defense ?? 2,
        magic: row.magic ?? 2,
        athletics: row.athletics ?? 2,
        agility: row.agility ?? 2,
        dice: row.dice,
        items: items.map(ownedFrom),
    }
}

function battleFrom(row: Doc<'combats'>): CombatState {
    return {
        playerId: row.playerId,
        spaceId: row.spaceId,
        enemy: {
            name: row.enemyName,
            element: elementOf(row.enemyElement),
            hp: row.enemyMaxHp,
            attack: row.enemyAttack,
            defense: row.enemyDefense ?? 2,
            magic: row.enemyMagic ?? 2,
            athletics: row.enemyAthletics ?? 2,
            agility: row.enemyAgility ?? 2,
            reward: row.reward,
        },
        enemyHp: row.enemyHp,
        enemyDefensePenalty: row.enemyDefensePenalty ?? 0,
        enemyMagicPenalty: row.enemyMagicPenalty ?? 0,
        enemyAthleticsPenalty: row.enemyAthleticsPenalty ?? 0,
        enemyAgilityPenalty: row.enemyAgilityPenalty ?? 0,
        playerDefensePenalty: row.playerDefensePenalty ?? 0,
        playerMagicPenalty: row.playerMagicPenalty ?? 0,
        playerAthleticsPenalty: row.playerAthleticsPenalty ?? 0,
        playerAgilityPenalty: row.playerAgilityPenalty ?? 0,
        round: row.round,
        lastAttack:
            row.lastAttack === undefined ? { _: 'none' } : { _: 'some', val: row.lastAttack },
        lastGuard:
            row.lastGuard === undefined
                ? { _: 'none' }
                : { _: 'some', val: guardOf(row.lastGuard) },
        lastDamage:
            row.lastDamage === undefined ? { _: 'none' } : { _: 'some', val: row.lastDamage },
        message: row.message,
    }
}

function drawnFrom(row: Doc<'encounters'>): EncounterState {
    const kind: Game_Encounter_Kind = row.kind === 'combat' ? { _: 'combat' } : { _: 'event' }
    return {
        playerId: row.playerId,
        spaceId: row.spaceId,
        kind: kind,
        outcome: {
            id: row.outcomeId,
            kind: kind,
            title: row.title,
            description: row.description,
            goldDelta: row.goldDelta,
            hpDelta: row.hpDelta,
            weight: 0,
        },
        wheelIndex: row.wheelIndex,
        resolved: row.status === 'resolved',
    }
}

function routeFrom(row: Doc<'roomSelections'>): Selection {
    return { playerId: row.playerId, destination: row.destination, path: row.path ?? [] }
}

function cameraFrom(row: Doc<'roomCameras'>): Camera {
    return {
        free: row.mode === 'free',
        targetX: Math.round(row.targetX * 100),
        targetZ: Math.round(row.targetZ * 100),
        distance: row.distance,
    }
}

function phaseFrom(
    room: Doc<'rooms'>,
    combat: Doc<'combats'> | null,
    encounter: Doc<'encounters'> | null,
    selection: Doc<'roomSelections'> | null,
): Phase {
    if (room.status === 'lobby') {
        return { _: 'lobby' }
    }
    if (room.status === 'finished') {
        return { _: 'finished', winner: room.activePlayerId ?? '' }
    }
    const named = room.phase ?? (room.remainingMoves > 0 ? 'moving' : 'awaitingRoll')
    if (named === 'moving') {
        return {
            _: 'moving',
            moves: room.remainingMoves,
            selection: selection ? { _: 'some', val: routeFrom(selection) } : { _: 'none' },
        }
    }
    if (named === 'combatAttack' && combat) {
        return { _: 'combat', battle: battleFrom(combat), stage: { _: 'attackerChoice' } }
    }
    if (named === 'combatDefend' && combat) {
        return { _: 'combat', battle: battleFrom(combat), stage: { _: 'defenderChoice' } }
    }
    if (named === 'revealingEncounter' && encounter && encounter.status === 'revealing') {
        return { _: 'encounter', drawn: drawnFrom(encounter) }
    }
    if (named === 'shopping' && room.shopKind) {
        return { _: 'shop', kind: shopKindOf(room.shopKind) }
    }
    return { _: 'awaitingRoll' }
}

export async function loadState(ctx: MutationCtx, roomId: Id<'rooms'>): Promise<State> {
    const room = await ctx.db.get('rooms', roomId)
    if (!room) {
        throw new ConvexError('That room does not exist.')
    }
    const rows = await ctx.db
        .query('players')
        .withIndex('by_room', (query) => query.eq('roomId', roomId))
        .take(4)
    const ordered = rows.sort((a, b) => a.joinedAt - b.joinedAt)
    const players: PlayerState[] = []
    for (const row of ordered) {
        const items = await ctx.db
            .query('playerItems')
            .withIndex('by_playerId', (query) => query.eq('playerId', row._id))
            .take(40)
        players.push(heroFrom(row, items))
    }
    const combat = room.activeCombatId ? await ctx.db.get(room.activeCombatId) : null
    const encounter = room.activeEncounterId ? await ctx.db.get(room.activeEncounterId) : null
    const selection = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const camera = await ctx.db
        .query('roomCameras')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const turn = ordered.findIndex((candidate) => candidate._id === room.activePlayerId)
    return {
        code: room.code,
        host: room.hostAuthId ?? '',
        players: players,
        turn: turn < 0 ? 0 : turn,
        round: room.round,
        phase: phaseFrom(room, combat, encounter, selection),
        message: room.message,
        lastRoll: room.lastRoll ?? [],
        rng: room.rngState ?? normalizeSeed(room._creationTime),
        rngCounter: room.rngCounter ?? 0,
        camera: camera ? { _: 'some', val: cameraFrom(camera) } : { _: 'none' },
        version: room.eventVersion ?? 0,
    }
}

export function emptyState(): State {
    return {
        code: '',
        host: '',
        players: [],
        turn: 0,
        round: 1,
        phase: { _: 'lobby' },
        message: '',
        lastRoll: [],
        rng: 1,
        rngCounter: 0,
        camera: { _: 'none' },
        version: 0,
    }
}
