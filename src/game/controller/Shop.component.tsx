import { itemsForShop, type ShopKind } from '../../../shared/item.system'

type ShopProps = {
    kind: ShopKind
    gold: number
    onBuy: (itemId: string) => void
    onLeave: () => void
}

const SHOP_NAMES: Record<ShopKind, string> = {
    armoury: 'Wildroot Armoury',
    jeweller: 'Moonbeam Jeweller',
    weapons: 'Ironbranch Weapons',
    items: 'Wayfarer Item Shop',
    magic: 'Bluecap Magic Shop',
}

export function Shop({ kind, gold, onBuy, onLeave }: ShopProps) {
    return (
        <section className="shop-panel" aria-label={SHOP_NAMES[kind]}>
            <header>
                <div>
                    <span className="eyebrow">◈ {gold} gold</span>
                    <h2>{SHOP_NAMES[kind]}</h2>
                </div>
            </header>
            <div className="shop-list">
                {itemsForShop(kind).map((item) => (
                    <article className="shop-item" key={item.id}>
                        <span className="shop-item-icon">{item.icon}</span>
                        <div>
                            <strong>{item.name}</strong>
                            <small>{item.description}</small>
                        </div>
                        <button
                            type="button"
                            aria-label={`Buy ${item.name} for ${item.price} gold`}
                            disabled={gold < item.price}
                            onClick={() => onBuy(item.id)}
                        >
                            {item.price} ◈
                        </button>
                    </article>
                ))}
            </div>
            <button type="button" className="inventory-back" onClick={onLeave}>
                <span>B</span> Leave shop
            </button>
        </section>
    )
}
