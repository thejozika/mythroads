import { QRCodeSVG } from 'qrcode.react'
import { BoardScene } from '../board/Board.scene'
import type { RoomState } from '../game.type'
import { CombatArena } from './CombatArena.component'
import { EncounterWheel } from './EncounterWheel.component'

type BoardDisplayProps = {
    state: NonNullable<RoomState>
    onStart?: () => void
}

export function BoardDisplay({ state, onStart }: BoardDisplayProps) {
    const { room, players } = state
    const active = players.find((player) => player._id === room.activePlayerId)
    const joinUrl = `${window.location.origin}/join/${room.code}`

    return (
        <main className="display-shell">
            <div className="canvas-wrap">
                <BoardScene
                    players={players}
                    activePlayer={active}
                    remainingMoves={room.remainingMoves}
                    cameraState={state.camera}
                    selectedDestination={state.selection?.destination}
                    selectedPath={state.selection?.path}
                    lastRoll={room.lastRoll}
                    combat={state.combat}
                />
            </div>
            {!state.combat && (
                <header className="display-header">
                    <div>
                        <span className="eyebrow">Round {room.round || 1}</span>
                        <h1>Wildroot Crossing</h1>
                    </div>
                    <div className="legend">
                        <span>
                            <i className="combat-dot" /> Combat
                        </span>
                        <span>
                            <i className="event-dot" /> Event
                        </span>
                        <span>
                            <i className="shop-dot" /> Shop
                        </span>
                        <span>
                            <i className="castle-dot" /> Castle
                        </span>
                    </div>
                </header>
            )}
            {!state.combat && (
                <aside className="roster">
                    {players.map((player) => (
                        <div
                            className={`player-card ${active?._id === player._id ? 'active' : ''}`}
                            key={player._id}
                        >
                            <span className="player-gem" style={{ background: player.color }} />
                            <div>
                                <strong>{player.name}</strong>
                                <small>
                                    ♥ {player.hp}/{player.maxHp} · ◈ {player.gold}
                                </small>
                            </div>
                        </div>
                    ))}
                </aside>
            )}
            {!state.combat && (
                <section className="status-ribbon">
                    {room.status === 'lobby' ? (
                        <>
                            <strong>Waiting for heroes</strong>
                            <span>{players.length} joined</span>
                        </>
                    ) : (
                        <>
                            <strong>
                                {active ? `${active.name}'s turn` : 'Adventure complete'}
                            </strong>
                            <span>{room.message}</span>
                            {room.remainingMoves > 0 && (
                                <small>{room.remainingMoves} movement</small>
                            )}
                        </>
                    )}
                </section>
            )}
            {room.status === 'lobby' && (
                <div className="join-panel">
                    <QRCodeSVG value={joinUrl} size={112} bgColor="#f7f1de" fgColor="#17221e" />
                    <div>
                        <span className="eyebrow">Scan to join</span>
                        <strong>{room.code}</strong>
                    </div>
                    {onStart && (
                        <button
                            type="button"
                            className="primary"
                            disabled={players.length < 1}
                            onClick={onStart}
                        >
                            Start adventure
                        </button>
                    )}
                </div>
            )}
            {state.encounter && <EncounterWheel encounter={state.encounter} />}
            {state.combat && <CombatArena combat={state.combat} player={active} />}
        </main>
    )
}
