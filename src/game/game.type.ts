export type Room = {
    _id: string
    code: string
    status: 'lobby' | 'playing' | 'finished'
    activePlayerId?: string
    remainingMoves: number
    lastRoll?: number[]
    message: string
    round: number
    phase?:
        | 'awaitingRoll'
        | 'moving'
        | 'revealingEncounter'
        | 'shopping'
        | 'combatAttack'
        | 'combatDefend'
    activeEncounterId?: string
    activeCombatId?: string
    shopKind?: 'armoury' | 'jeweller' | 'weapons' | 'items' | 'magic'
}

export type Player = {
    _id: string
    name: string
    color: string
    position: number
    previousPosition?: number
    gold: number
    hp: number
    maxHp: number
    attack: number
    defense?: number
    magic?: number
    athletics?: number
    agility?: number
    mp?: number
    maxMp?: number
    dice: number[]
    joinedAt: number
}

export type Encounter = {
    _id: string
    playerId: string
    kind: 'combat' | 'event'
    title: string
    description: string
    goldDelta: number
    hpDelta: number
    wheelIndex: number
    createdAt: number
}

export type OwnedItem = {
    _id: string
    itemId: string
    equippedSlot?: EquipmentSlot
}

export type RoomCamera = {
    mode: 'follow' | 'free'
    targetX: number
    targetZ: number
    distance: number
}

export type Combat = {
    _id: string
    playerId: string
    enemyName: string
    enemyElement: 'fire' | 'water' | 'wind' | 'earth'
    enemyHp: number
    enemyMaxHp: number
    enemyDefense?: number
    enemyMagic?: number
    enemyAthletics?: number
    enemyAgility?: number
    round: number
    phase: 'attack' | 'defend' | 'resolved'
    lastAttack?: string
    lastGuard?: string
    lastDamage?: number
    message: string
}

export type MovementSelection = {
    playerId: string
    destination: number
}

export type RoomState = {
    room: Room
    players: Player[]
    encounter: Encounter | null
    combat: Combat | null
    selection: MovementSelection | null
    camera: RoomCamera | null
} | null
import type { EquipmentSlot } from '../../shared/item.system'
