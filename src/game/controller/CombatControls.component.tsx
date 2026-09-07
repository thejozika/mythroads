import {
    ATTACK_LABELS,
    GUARD_LABELS,
    GUARD_STANCES,
    MAGIC_SPELLS,
    PHYSICAL_ATTACKS,
    type CombatAttack,
    type GuardStance,
} from '../../../shared/combat.system'
import type { Combat, Player } from '../game.type'
import './combat-controls.css'

export function CombatControls({
    combat,
    player,
    onAttack,
    onGuard,
}: {
    combat: Combat
    player: Player
    onAttack: (attack: CombatAttack) => void
    onGuard: (guard: GuardStance) => void
}) {
    const attacking = combat.phase === 'attack'
    return (
        <section className="combat-controls">
            <header>
                <div>
                    <span className="eyebrow">Round {combat.round}</span>
                    <h2>{attacking ? 'Choose your strike' : 'Read the attack'}</h2>
                </div>
                <div className="combat-health">
                    <span>♥ {player.hp}</span>
                    <span>
                        {combat.enemyName} ♥ {combat.enemyHp}
                    </span>
                </div>
            </header>
            {attacking ? (
                <>
                    <div className="combat-choice-grid physical-choices">
                        {PHYSICAL_ATTACKS.map((attack) => (
                            <button type="button" onClick={() => onAttack(attack)} key={attack}>
                                <strong>{ATTACK_LABELS[attack]}</strong>
                                <small>{attack === 'stab' ? 'Reliable' : 'Guard matchup'}</small>
                            </button>
                        ))}
                    </div>
                    <div className="combat-choice-grid magic-choices">
                        {MAGIC_SPELLS.map((spell) => (
                            <button
                                type="button"
                                disabled={(player.mp ?? 5) < 2}
                                onClick={() => onAttack(spell)}
                                key={spell}
                            >
                                <strong>{ATTACK_LABELS[spell]}</strong>
                                <small>2 MP · {spell}</small>
                            </button>
                        ))}
                    </div>
                </>
            ) : (
                <div className="combat-choice-grid guard-choices">
                    {GUARD_STANCES.map((guard) => (
                        <button type="button" onClick={() => onGuard(guard)} key={guard}>
                            <strong>{GUARD_LABELS[guard]}</strong>
                            <small>Strong, neutral, or weak by strike</small>
                        </button>
                    ))}
                </div>
            )}
            <p>{combat.message}</p>
        </section>
    )
}
