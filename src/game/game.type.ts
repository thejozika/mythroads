export type Room = {
    _id: string
    code: string
    status: 'lobby' | 'playing' | 'finished'
    activePlayerId?: string
    remainingMoves: number
    lastRoll?: number[]
    message: string
    round: number
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

export type RoomState = { room: Room; players: Player[] } | null
