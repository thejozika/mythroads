import { outcomesFor } from '../../../shared/encounter.system'
import type { Encounter } from '../game.type'
import './encounter.css'

export function EncounterWheel({ encounter }: { encounter: Encounter }) {
    const outcomes = outcomesFor(encounter.kind)
    const segment = 360 / outcomes.length
    const turn = 360 * 5 + (360 - encounter.wheelIndex * segment - segment / 2)
    return (
        <section className={`encounter-overlay ${encounter.kind}`} aria-live="assertive">
            <span className="eyebrow">{encounter.kind} wheel</span>
            <div className="wheel-stage">
                <div className="wheel-pointer">▼</div>
                <div
                    className="encounter-wheel"
                    style={{ '--wheel-turn': `${turn}deg` } as React.CSSProperties}
                >
                    {outcomes.map((outcome, index) => (
                        <span
                            key={outcome.id}
                            style={{ transform: `rotate(${index * segment + segment / 2}deg)` }}
                        >
                            {index + 1}
                        </span>
                    ))}
                </div>
            </div>
            <div className="encounter-result">
                <h2>{encounter.title}</h2>
                <p>{encounter.description}</p>
                <strong>
                    {encounter.goldDelta !== 0 &&
                        `${encounter.goldDelta > 0 ? '+' : ''}${encounter.goldDelta} gold`}
                    {encounter.goldDelta !== 0 && encounter.hpDelta !== 0 && ' · '}
                    {encounter.hpDelta !== 0 &&
                        `${encounter.hpDelta > 0 ? '+' : ''}${encounter.hpDelta} health`}
                    {encounter.goldDelta === 0 && encounter.hpDelta === 0 && 'No effect'}
                </strong>
            </div>
        </section>
    )
}
