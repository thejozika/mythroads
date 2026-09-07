import type { Player } from '../game.type'
import { identifiedDice } from './dice-view.util'

export function HeroStatus({
    code,
    player,
    active,
    lastRoll,
    remainingMoves,
}: {
    code: string
    player: Player
    active: boolean
    lastRoll?: number[]
    remainingMoves: number
}) {
    return (
        <>
            <header className="phone-header">
                <div>
                    <span className="eyebrow">Room {code}</span>
                    <h1>{player.name}</h1>
                </div>
                <span className="turn-pill">{active ? 'Your turn' : 'Waiting'}</span>
            </header>
            <div className="stat-grid">
                <div>
                    <small>Health</small>
                    <strong>
                        ♥ {player.hp}/{player.maxHp}
                    </strong>
                </div>
                <div>
                    <small>Attack</small>
                    <strong>AT {player.attack}</strong>
                </div>
                <div>
                    <small>Defense</small>
                    <strong>DF {player.defense ?? 2}</strong>
                </div>
                <div>
                    <small>Magic</small>
                    <strong>MG {player.magic ?? 2}</strong>
                </div>
                <div>
                    <small>Athletics</small>
                    <strong>ATH {player.athletics ?? 2}</strong>
                </div>
                <div>
                    <small>Agility</small>
                    <strong>AGI {player.agility ?? 2}</strong>
                </div>
                <div>
                    <small>Gold</small>
                    <strong>◈ {player.gold}</strong>
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
                {lastRoll && active && (
                    <p className="roll-result">
                        Rolled {lastRoll.join(' + ')} ={' '}
                        <strong>{lastRoll.reduce((sum, value) => sum + value, 0)}</strong>
                    </p>
                )}
            </section>
            {active && remainingMoves > 0 && (
                <p className="steps-left">{remainingMoves} steps remaining</p>
            )}
        </>
    )
}
