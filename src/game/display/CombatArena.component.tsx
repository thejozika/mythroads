import type { Combat, Player } from '../game.type'
import './combat-arena.css'

export function CombatArena({ combat, player }: { combat: Combat; player?: Player }) {
    return (
        <section className="combat-arena" aria-live="polite">
            <header>
                <span>Round {combat.round}</span>
                <strong>{combat.phase === 'attack' ? 'Choose an attack' : 'Choose a guard'}</strong>
            </header>
            <div className="combatants">
                <div>
                    <small>{player?.name ?? 'Hero'}</small>
                    <strong>
                        ♥ {player?.hp ?? 0}/{player?.maxHp ?? 0}
                    </strong>
                </div>
                <b>VS</b>
                <div>
                    <small>
                        {combat.enemyName} · {combat.enemyElement}
                    </small>
                    <strong>
                        ♥ {combat.enemyHp}/{combat.enemyMaxHp}
                    </strong>
                </div>
            </div>
            <p>{combat.message}</p>
        </section>
    )
}
