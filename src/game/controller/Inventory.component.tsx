type InventoryProps = {
    dice: number[]
    gold: number
    onClose: () => void
}

export function Inventory({ dice, gold, onClose }: InventoryProps) {
    return (
        <section className="inventory-panel" aria-label="Inventory">
            <header>
                <div>
                    <span className="eyebrow">Private inventory</span>
                    <h2>Travel pack</h2>
                </div>
                <button type="button" onClick={onClose} aria-label="Close inventory">
                    ×
                </button>
            </header>
            <div className="inventory-gold">◈ {gold} gold</div>
            <span className="eyebrow">Movement dice</span>
            <div className="dice-row">
                {identifiedDice(dice).map((die) => (
                    <div className="die" key={die.id}>
                        D{die.sides}
                    </div>
                ))}
            </div>
            <p>Your starter dice cannot break. Collected special dice will appear here later.</p>
            <button type="button" className="inventory-back" onClick={onClose}>
                <span>B</span> Close inventory
            </button>
        </section>
    )
}
import { identifiedDice } from './dice-view.util'
