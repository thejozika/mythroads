import type { Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'

export async function createPlayer(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    data: { name: string; color: string },
    authId?: string,
) {
    const playerId = await ctx.db.insert('players', {
        roomId,
        ...(authId ? { authId } : {}),
        name: data.name,
        color: data.color,
        position: 0,
        gold: 10,
        hp: 10,
        maxHp: 10,
        attack: 2,
        defense: 2,
        magic: 2,
        athletics: 2,
        agility: 2,
        dice: [4, 6],
        joinedAt: Date.now(),
    })
    await Promise.all([
        ctx.db.insert('playerItems', {
            playerId,
            itemId: 'ember_grimoire',
            equippedSlot: 'offensiveMagic',
            purchasedAt: Date.now(),
        }),
        ctx.db.insert('playerItems', {
            playerId,
            itemId: 'aegis_script',
            equippedSlot: 'defensiveMagic',
            purchasedAt: Date.now(),
        }),
    ])
    return playerId
}
