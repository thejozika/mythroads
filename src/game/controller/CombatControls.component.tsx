import {
    ATTACK_LABELS,
    GUARD_LABELS,
    GUARD_STANCES,
    PHYSICAL_ATTACKS,
    type CombatAttack,
    type GuardStance,
} from '../../../shared/combat.system'
import { equippedMagic } from '../../../shared/item.system'
import type { Combat, OwnedItem, Player } from '../game.type'
import './combat-controls.css'

export function CombatControls({
    combat,
    player,
    onAttack,
    onGuard,
    items,
}: {
    combat: Combat
    player: Player
    onAttack: (attack: CombatAttack) => void
    onGuard: (guard: GuardStance) => void
    items: OwnedItem[]
}) {
    const attacking = combat.phase === 'attack'
    const magic = equippedMagic(items)
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
                        <button
                            type="button"
                            disabled={(player.mp ?? 5) < 2}
                            onClick={() => onAttack(magic.spell)}
                        >
                            <strong>✦ {ATTACK_LABELS[magic.spell]}</strong>
                            <small>Equipped · 2 MP · {magic.spell}</small>
                        </button>
                    </div>
                </>
            ) : (
                <div className="combat-choice-grid guard-choices">
                    {GUARD_STANCES.map((guard) => (
                        <button type="button" onClick={() => onGuard(guard)} key={guard}>
                            <strong>{GUARD_LABELS[guard]}</strong>
                            <small>
                                {guard === 'ward'
                                    ? 'Strong vs magic · exposed to steel'
                                    : 'Strong, neutral, or weak by strike'}
                            </small>
                        </button>
                    ))}
                </div>
            )}
            <p>{combat.message}</p>
        </section>
    )
}
