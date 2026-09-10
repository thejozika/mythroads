/** Generated from proofs/Mythroads/Game/Player.lean. Do not edit by hand. */
import type { Id } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'

export async function createPlayer(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    data: { name: string; color: string },
    authId: string | undefined,
): Promise<Id<'players'>> {
    const createdAt = Date.now()
    const playerId = await ctx.db.insert('players', {
        roomId: roomId,
        authId: authId,
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
        joinedAt: createdAt,
    })
    await ctx.db.insert('playerItems', {
        playerId: playerId,
        itemId: 'ember_grimoire',
        equippedSlot: 'offensiveMagic',
        purchasedAt: createdAt,
    })
    await ctx.db.insert('playerItems', {
        playerId: playerId,
        itemId: 'aegis_script',
        equippedSlot: 'defensiveMagic',
        purchasedAt: createdAt,
    })
    return playerId
}
