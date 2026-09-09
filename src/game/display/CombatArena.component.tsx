import type { Combat, PublicPlayer } from '../game.type'
import './combat-arena.css'

export function CombatArena({ combat, player }: { combat: Combat; player?: PublicPlayer }) {
    return (
        <section className="combat-arena" aria-live="polite">
            <header>
                <span>Round {combat.round}</span>
                <strong>{combat.phase === 'attack' ? 'Choose an attack' : 'Choose a guard'}</strong>
            </header>
            <div className="combatants">
                <div>
                    <small>{player?.name ?? 'Hero'}</small>
                    <strong>Choosing privately</strong>
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
