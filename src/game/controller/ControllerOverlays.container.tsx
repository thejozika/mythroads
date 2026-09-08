import { useMutation, useQuery } from 'convex/react'
import { api } from '../../../convex/_generated/api'
import type { Id } from '../../../convex/_generated/dataModel'
import type { CombatAttack, GuardStance } from '../../../shared/combat.system'
import type { EquipmentSlot, ShopKind } from '../../../shared/item.system'
import { gameCommand } from '../game-event.util'
import type { Combat, Player } from '../game.type'
import { CombatControls } from './CombatControls.component'
import { Inventory } from './Inventory.component'
import { Shop } from './Shop.component'

type Props = {
    roomId: Id<'rooms'>
    playerId: Id<'players'>
    player: Player
    active: boolean
    phase: string
    shopKind?: ShopKind
    combat: Combat | null
    inventoryOpen: boolean
    onCloseInventory: () => void
}

export function ControllerOverlays({
    roomId,
    playerId,
    player,
    active,
    phase,
    shopKind,
    combat,
    inventoryOpen,
    onCloseInventory,
}: Props) {
    const dispatch = useMutation(api.game.dispatch)
    const items = useQuery(api.shops.inventory, { playerId })
    const subjects = { roomId, playerId }
    const attack = (choice: CombatAttack) =>
        dispatch(gameCommand({ type: 'combat.attack', subjects, data: { attack: choice } }))
    const guard = (choice: GuardStance) =>
        dispatch(gameCommand({ type: 'combat.guard', subjects, data: { guard: choice } }))

    return (
        <>
            {inventoryOpen && (
                <Inventory
                    dice={player.dice}
                    gold={player.gold}
                    items={items ?? []}
                    onEquip={(ownedItemId, slot: EquipmentSlot) =>
                        dispatch(
                            gameCommand({
                                type: 'inventory.equip',
                                subjects: {
                                    playerId,
                                    playerItemId: ownedItemId as Id<'playerItems'>,
                                },
                                data: { slot },
                            }),
                        )
                    }
                    onClose={onCloseInventory}
                />
            )}
            {active && phase === 'shopping' && shopKind && (
                <Shop
                    kind={shopKind}
                    gold={player.gold}
                    onBuy={(itemId) =>
                        dispatch(gameCommand({ type: 'shop.buy', subjects, data: { itemId } }))
                    }
                    onLeave={() =>
                        dispatch(gameCommand({ type: 'shop.leave', subjects, data: {} }))
                    }
                />
            )}
            {active && combat && (
                <CombatControls
                    combat={combat}
                    player={player}
                    onAttack={attack}
                    onGuard={guard}
                    items={items ?? []}
                />
            )}
        </>
    )
}
