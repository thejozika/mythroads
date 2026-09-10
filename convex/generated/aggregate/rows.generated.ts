/** Generated from proofs/Mythroads/Backend/Aggregate/Rows.lean. Do not edit by hand. */
import type {
    CombatStage,
    CombatState,
    EncounterState,
    Game_Inventory_EquipmentSlot,
    Option,
    Phase,
    PlayerState,
} from '../../../shared/engine.system'
import type { Doc, Id } from '../../_generated/dataModel'

export type RoomPhaseColumn = NonNullable<Doc<'rooms'>['phase']>

export type RoomStatusColumn = Doc<'rooms'>['status']

export type SlotColumn = Doc<'playerItems'>['equippedSlot']

export function slotColumn(slot: Option<Game_Inventory_EquipmentSlot>): SlotColumn {
    return slot._ === 'none' ? undefined : slot.val._
}

export function numberColumn(value: Option<number>): number | undefined {
    return value._ === 'none' ? undefined : value.val
}

export function penaltyColumn(value: number): number | undefined {
    return value === 0 ? undefined : value
}

export function phaseColumn(phase: Phase): RoomPhaseColumn {
    if (phase._ === 'moving') {
        return 'moving'
    }
    if (phase._ === 'combat') {
        return phase.stage._ === 'defenderChoice' ? 'combatDefend' : 'combatAttack'
    }
    if (phase._ === 'encounter') {
        return 'revealingEncounter'
    }
    if (phase._ === 'shop') {
        return 'shopping'
    }
    return 'awaitingRoll'
}

export function statusColumn(phase: Phase): RoomStatusColumn {
    if (phase._ === 'lobby') {
        return 'lobby'
    }
    if (phase._ === 'finished') {
        return 'finished'
    }
    return 'playing'
}

export function movesColumn(phase: Phase): number {
    return phase._ === 'moving' ? phase.moves : 0
}

export function stageColumn(stage: CombatStage): Doc<'combats'>['phase'] {
    if (stage._ === 'resolved') {
        return 'resolved'
    }
    return stage._ === 'defenderChoice' ? 'defend' : 'attack'
}

export function heroColumns(hero: PlayerState) {
    return {
        authId: hero.owner === '' ? undefined : hero.owner,
        name: hero.name,
        color: hero.color,
        position: hero.position,
        previousPosition: numberColumn(hero.previousPosition),
        gold: hero.gold,
        hp: hero.hp,
        maxHp: hero.maxHp,
        attack: hero.attack,
        defense: hero.defense,
        magic: hero.magic,
        athletics: hero.athletics,
        agility: hero.agility,
        dice: hero.dice,
    }
}

export function combatColumns(roomId: Id<'rooms'>, battle: CombatState, stage: CombatStage) {
    return {
        roomId: roomId,
        playerId: battle.playerId as Id<'players'>,
        spaceId: battle.spaceId,
        enemyName: battle.enemy.name,
        enemyElement: battle.enemy.element._,
        enemyHp: battle.enemyHp,
        enemyMaxHp: battle.enemy.hp,
        enemyAttack: battle.enemy.attack,
        enemyDefense: battle.enemy.defense,
        enemyMagic: battle.enemy.magic,
        enemyAthletics: battle.enemy.athletics,
        enemyAgility: battle.enemy.agility,
        enemyDefensePenalty: penaltyColumn(battle.enemyDefensePenalty),
        enemyMagicPenalty: penaltyColumn(battle.enemyMagicPenalty),
        enemyAthleticsPenalty: penaltyColumn(battle.enemyAthleticsPenalty),
        enemyAgilityPenalty: penaltyColumn(battle.enemyAgilityPenalty),
        playerDefensePenalty: penaltyColumn(battle.playerDefensePenalty),
        playerMagicPenalty: penaltyColumn(battle.playerMagicPenalty),
        playerAthleticsPenalty: penaltyColumn(battle.playerAthleticsPenalty),
        playerAgilityPenalty: penaltyColumn(battle.playerAgilityPenalty),
        reward: battle.enemy.reward,
        round: battle.round,
        phase: stageColumn(stage),
        lastAttack: battle.lastAttack._ === 'none' ? undefined : battle.lastAttack.val,
        lastGuard: battle.lastGuard._ === 'none' ? undefined : battle.lastGuard.val._,
        lastDamage: numberColumn(battle.lastDamage),
        message: battle.message,
    }
}

export function encounterColumns(roomId: Id<'rooms'>, drawn: EncounterState) {
    return {
        roomId: roomId,
        playerId: drawn.playerId as Id<'players'>,
        spaceId: drawn.spaceId,
        kind: drawn.kind._,
        outcomeId: drawn.outcome.id,
        title: drawn.outcome.title,
        description: drawn.outcome.description,
        goldDelta: drawn.outcome.goldDelta,
        hpDelta: drawn.outcome.hpDelta,
        wheelIndex: drawn.wheelIndex,
        status: drawn.resolved ? ('resolved' as const) : ('revealing' as const),
    }
}
