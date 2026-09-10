import { query } from './_generated/server'
import { inventoryQueryDefinition } from './generated/inventory.generated'

export const inventory = query(inventoryQueryDefinition)
export { equipItem } from './generated/inventory.generated'
export { buyItem, leaveShop } from './generated/shop.generated'
