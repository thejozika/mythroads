export type ShopKind = 'armoury' | 'jeweller' | 'weapons' | 'items' | 'magic'

export type EquipmentSlot =
    | 'weapon'
    | 'helmet'
    | 'body'
    | 'gloves'
    | 'boots'
    | 'cape'
    | 'amulet'
    | 'ringLeft'
    | 'ringRight'

export type ItemDefinition = {
    id: string
    name: string
    icon: string
    price: number
    shop: ShopKind
    description: string
    slots: EquipmentSlot[]
}

export const EQUIPMENT_SLOTS: { id: EquipmentSlot; label: string; icon: string }[] = [
    { id: 'helmet', label: 'Helmet', icon: '⸙' },
    { id: 'amulet', label: 'Amulet', icon: '✧' },
    { id: 'weapon', label: 'Weapon', icon: '⚔' },
    { id: 'body', label: 'Body', icon: '◈' },
    { id: 'cape', label: 'Cape / Pack', icon: '◒' },
    { id: 'gloves', label: 'Gloves', icon: '◖' },
    { id: 'boots', label: 'Boots', icon: '◡' },
    { id: 'ringLeft', label: 'Ring I', icon: '○' },
    { id: 'ringRight', label: 'Ring II', icon: '○' },
]

export const ITEMS: ItemDefinition[] = [
    {
        id: 'oak_blade',
        name: 'Oak Blade',
        icon: '⚔',
        price: 5,
        shop: 'weapons',
        description: 'A dependable first weapon.',
        slots: ['weapon'],
    },
    {
        id: 'iron_sword',
        name: 'Iron Sword',
        icon: '†',
        price: 12,
        shop: 'weapons',
        description: 'Heavy, honest steel.',
        slots: ['weapon'],
    },
    {
        id: 'trail_helm',
        name: 'Trail Helm',
        icon: '⸙',
        price: 7,
        shop: 'armoury',
        description: 'Keeps branches and blows away.',
        slots: ['helmet'],
    },
    {
        id: 'padded_coat',
        name: 'Padded Coat',
        icon: '◈',
        price: 8,
        shop: 'armoury',
        description: 'Light protection for long roads.',
        slots: ['body'],
    },
    {
        id: 'grip_gloves',
        name: 'Grip Gloves',
        icon: '◖',
        price: 5,
        shop: 'armoury',
        description: 'Never drop the important thing.',
        slots: ['gloves'],
    },
    {
        id: 'swift_boots',
        name: 'Swift Boots',
        icon: '◡',
        price: 6,
        shop: 'armoury',
        description: 'Made for muddy shortcuts.',
        slots: ['boots'],
    },
    {
        id: 'ranger_cape',
        name: 'Ranger Cape',
        icon: '◒',
        price: 9,
        shop: 'armoury',
        description: 'A cape with a secret travel pack.',
        slots: ['cape'],
    },
    {
        id: 'amber_amulet',
        name: 'Amber Amulet',
        icon: '✧',
        price: 9,
        shop: 'jeweller',
        description: 'Warm luck trapped in amber.',
        slots: ['amulet'],
    },
    {
        id: 'copper_ring',
        name: 'Copper Ring',
        icon: '○',
        price: 6,
        shop: 'jeweller',
        description: 'Simple magic, carefully set.',
        slots: ['ringLeft', 'ringRight'],
    },
    {
        id: 'moon_ring',
        name: 'Moon Ring',
        icon: '◉',
        price: 13,
        shop: 'jeweller',
        description: 'Glints when danger is close.',
        slots: ['ringLeft', 'ringRight'],
    },
    {
        id: 'red_potion',
        name: 'Red Potion',
        icon: '♥',
        price: 4,
        shop: 'items',
        description: 'A future-use healing item.',
        slots: [],
    },
    {
        id: 'smoke_bomb',
        name: 'Smoke Bomb',
        icon: '◌',
        price: 5,
        shop: 'items',
        description: 'A future-use escape item.',
        slots: [],
    },
    {
        id: 'spark_wand',
        name: 'Spark Wand',
        icon: '⁂',
        price: 11,
        shop: 'magic',
        description: 'Crackles with beginner magic.',
        slots: ['weapon'],
    },
    {
        id: 'ward_charm',
        name: 'Ward Charm',
        icon: '❈',
        price: 10,
        shop: 'magic',
        description: 'A charm against wild curses.',
        slots: ['amulet'],
    },
]

export const getItem = (id: string) => ITEMS.find((item) => item.id === id)
export const itemsForShop = (shop: ShopKind) => ITEMS.filter((item) => item.shop === shop)
