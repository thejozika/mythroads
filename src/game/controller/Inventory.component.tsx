import { EQUIPMENT_SLOTS, getItem, type EquipmentSlot } from '../../../shared/item.system'
import type { OwnedItem } from '../game.type'
import { identifiedDice } from './dice-view.util'

type InventoryProps = {
    dice: number[]
    gold: number
    items: OwnedItem[]
    onEquip: (ownedItemId: string, slot: EquipmentSlot) => void
    onClose: () => void
}

export function Inventory({ dice, gold, items, onEquip, onClose }: InventoryProps) {
    const equipped = Object.fromEntries(items.map((item) => [item.equippedSlot, item]))
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
            <span className="eyebrow">Equipment</span>
            <div className="equipment-grid">
                {EQUIPMENT_SLOTS.map((slot) => {
                    const owned = equipped[slot.id]
                    const item = owned && getItem(owned.itemId)
                    return (
                        <div className={`equipment-slot slot-${slot.id}`} key={slot.id}>
                            <span>{item?.icon ?? slot.icon}</span>
                            <small>{slot.label}</small>
                            <strong>{item?.name ?? 'Empty'}</strong>
                        </div>
                    )
                })}
            </div>
            {items.length > 0 && (
                <>
                    <span className="eyebrow">Owned gear</span>
                    <div className="owned-items">
                        {items.map((owned) => {
                            const item = getItem(owned.itemId)
                            if (!item) return null
                            return (
                                <div key={owned._id}>
                                    <span>
                                        {item.icon} {item.name}
                                    </span>
                                    {!owned.equippedSlot && item.slots.length > 0 && (
                                        <button
                                            type="button"
                                            onClick={() =>
                                                onEquip(
                                                    owned._id,
                                                    item.slots.find((slot) => !equipped[slot]) ??
                                                        item.slots[0],
                                                )
                                            }
                                        >
                                            Equip
                                        </button>
                                    )}
                                </div>
                            )
                        })}
                    </div>
                </>
            )}
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
