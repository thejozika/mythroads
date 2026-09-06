export type Room = {
    _id: string
    code: string
    status: 'lobby' | 'playing' | 'finished'
    activePlayerId?: string
    remainingMoves: number
    lastRoll?: number[]
    message: string
    round: number
    phase?: 'awaitingRoll' | 'moving' | 'revealingEncounter' | 'shopping'
    activeEncounterId?: string
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
    equippedSlot?: string
}

export type RoomCamera = {
    mode: 'follow' | 'free'
    targetX: number
    targetZ: number
    distance: number
}

export type RoomState = {
    room: Room
    players: Player[]
    encounter: Encounter | null
    camera: RoomCamera | null
} | null
