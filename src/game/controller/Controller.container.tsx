import { useMutation, useQuery } from 'convex/react'
import { useState } from 'react'
import { api } from '../../../convex/_generated/api'
import type { Id } from '../../../convex/_generated/dataModel'
import { directionalSteps } from '../../../shared/controller-input.system'
import { Gamepad } from './Gamepad.component'
import { Inventory } from './Inventory.component'
import { identifiedDice } from './dice-view.util'
import './controller.css'

export function Controller({ code }: { code: string }) {
    const [inventoryOpen, setInventoryOpen] = useState(false)
    const state = useQuery(api.rooms.byCode, { code })
    const roll = useMutation(api.rooms.roll)
    const step = useMutation(api.rooms.step)
    const storedPlayerId = localStorage.getItem(`dicebound:${code}`)
    const playerId = storedPlayerId as Id<'players'> | null
    if (state === undefined) return <div className="loading">Finding your party…</div>
    if (!state || !playerId)
        return (
            <main className="phone-shell">
                <div className="controller-card">
                    <h1>Hero not found</h1>
                    <a className="button-link" href={`/join/${code}`}>
                        Join room
                    </a>
                </div>
            </main>
        )

    const player = state.players.find((candidate) => candidate._id === playerId)
    if (!player) return <div className="loading">This hero is no longer in the room.</div>
    const isActive = state.room.activePlayerId === playerId
    const canRoll = isActive && state.room.status === 'playing' && state.room.remainingMoves === 0
    const choices =
        isActive && state.room.remainingMoves > 0
            ? directionalSteps(player.position, player.previousPosition)
            : {}
    const directions = Object.fromEntries(
        Object.entries(choices).map(([direction, destination]) => [
            direction,
            () => step({ roomId: state.room._id, playerId, destination }),
        ]),
    )

    return (
        <main className="phone-shell" style={{ '--hero': player.color } as React.CSSProperties}>
            <div className="controller-card">
                <header className="phone-header">
                    <div>
                        <span className="eyebrow">Room {code}</span>
                        <h1>{player.name}</h1>
                    </div>
                    <span className="turn-pill">{isActive ? 'Your turn' : 'Waiting'}</span>
                </header>
                <div className="stat-grid">
                    <div>
                        <small>Health</small>
                        <strong>
                            ♥ {player.hp}/{player.maxHp}
                        </strong>
                    </div>
                    <div>
                        <small>Gold</small>
                        <strong>◈ {player.gold}</strong>
                    </div>
                    <div>
                        <small>Attack</small>
                        <strong>⚔ {player.attack}</strong>
                    </div>
                </div>
                <section className="dice-section">
                    <span className="eyebrow">Equipped movement dice</span>
                    <div className="dice-row">
                        {identifiedDice(player.dice).map((die) => (
                            <div className="die" key={die.id}>
                                D{die.sides}
                            </div>
                        ))}
                    </div>
                    {state.room.lastRoll && isActive && (
                        <p className="roll-result">
                            Rolled {state.room.lastRoll.join(' + ')} ={' '}
                            <strong>
                                {state.room.lastRoll.reduce((sum, value) => sum + value, 0)}
                            </strong>
                        </p>
                    )}
                </section>
                {isActive && state.room.remainingMoves > 0 && (
                    <p className="steps-left">{state.room.remainingMoves} steps remaining</p>
                )}
                <Gamepad
                    directions={directions}
                    canRoll={canRoll}
                    onRoll={() => roll({ roomId: state.room._id, playerId })}
                    onInventory={() => setInventoryOpen(true)}
                    onBack={() => setInventoryOpen(false)}
                    inventoryOpen={inventoryOpen}
                />
                <button
                    type="button"
                    className="inventory-button"
                    onClick={() => setInventoryOpen(true)}
                >
                    Inventory
                </button>
                {inventoryOpen && (
                    <Inventory
                        dice={player.dice}
                        gold={player.gold}
                        onClose={() => setInventoryOpen(false)}
                    />
                )}
                {!isActive && (
                    <div className="waiting-card">
                        <span className="pulse" /> Watch the main screen
                    </div>
                )}
                {state.room.status === 'lobby' && (
                    <div className="waiting-card">
                        <span className="pulse" /> Waiting for the host to start
                    </div>
                )}
                <p className="phone-message">{state.room.message}</p>
            </div>
        </main>
    )
}
