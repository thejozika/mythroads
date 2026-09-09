import { convexTest } from 'convex-test'
import { describe, expect, test } from 'vitest'
import { api } from '../../convex/_generated/api'
import schema from '../../convex/schema'

const modules = import.meta.glob(['../../convex/**/*.ts', '!../../convex/**/*.test.ts'])
const owner = {
    subject: 'owner',
    issuer: 'https://auth.dicebound.test',
    tokenIdentifier: 'https://auth.dicebound.test|owner',
}
const stranger = {
    subject: 'stranger',
    issuer: 'https://auth.dicebound.test',
    tokenIdentifier: 'https://auth.dicebound.test|stranger',
}

async function seedRoom() {
    const t = convexTest(schema, modules)
    const ids = await t.run(async (ctx) => {
        const roomId = await ctx.db.insert('rooms', {
            code: 'AUTH',
            hostAuthId: owner.tokenIdentifier,
            status: 'lobby',
            remainingMoves: 0,
            message: 'Waiting',
            round: 1,
            phase: 'awaitingRoll',
        })
        const playerId = await ctx.db.insert('players', {
            roomId,
            authId: owner.tokenIdentifier,
            name: 'Owner',
            color: '#4bd3c2',
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
            joinedAt: 1,
        })
        const itemId = await ctx.db.insert('playerItems', {
            playerId,
            itemId: 'ember_grimoire',
            purchasedAt: 1,
        })
        return { roomId, playerId, itemId }
    })
    return { t, ...ids }
}

describe('Hanko-backed game authorization', () => {
    test('owner can read their controller and inventory', async () => {
        const { t, playerId, itemId } = await seedRoom()
        const session = t.withIdentity(owner)
        const state = await session.query(api.rooms.queries.controllerByCode, {
            code: 'AUTH',
            playerId,
        })
        expect(state?.players.map((player) => player._id)).toEqual([playerId])
        expect(await session.query(api.shops.inventory, { playerId })).toEqual([
            expect.objectContaining({ _id: itemId }),
        ])
    })

    test('another account and an anonymous caller cannot use a hero', async () => {
        const { t, playerId } = await seedRoom()
        const args = { code: 'AUTH', playerId }
        await expect(
            t.withIdentity(stranger).query(api.rooms.queries.controllerByCode, args),
        ).rejects.toThrow(/another account/)
        await expect(t.query(api.rooms.queries.controllerByCode, args)).rejects.toThrow(/Sign in/)
        await expect(
            t.withIdentity(stranger).query(api.shops.inventory, { playerId }),
        ).rejects.toThrow(/another account/)
    })

    test('only the authenticated host can start a room', async () => {
        const { t, roomId } = await seedRoom()
        const event = { type: 'game.start' as const, subjects: { roomId }, data: {} }
        await expect(
            t.withIdentity(stranger).mutation(api.game.dispatch, { event }),
        ).rejects.toThrow(/Only the host/)
        await expect(t.mutation(api.game.dispatch, { event })).rejects.toThrow(/Sign in/)
        await expect(t.withIdentity(owner).mutation(api.game.dispatch, { event })).resolves.toEqual(
            { kind: 'accepted' },
        )
    })

    test('public display state excludes private stats and auth identifiers', async () => {
        const { t } = await seedRoom()
        const state = await t.query(api.rooms.queries.displayByCode, { code: 'AUTH' })
        expect(state?.canStart).toBe(false)
        expect(state?.room).not.toHaveProperty('hostAuthId')
        expect(state?.players[0]).not.toHaveProperty('authId')
        expect(state?.players[0]).not.toHaveProperty('gold')
        expect(state?.players[0]).not.toHaveProperty('hp')
        expect(state?.players[0]).not.toHaveProperty('dice')
    })

    test('deduplicated commands cannot leak results across accounts', async () => {
        const t = convexTest(schema, modules)
        const command = {
            commandId: 'owner-create-command',
            event: { type: 'room.create' as const, subjects: {}, data: {} },
        }
        await expect(t.withIdentity(owner).mutation(api.game.dispatch, command)).resolves.toEqual(
            expect.objectContaining({ kind: 'room.created' }),
        )
        await expect(t.withIdentity(stranger).mutation(api.game.dispatch, command)).rejects.toThrow(
            /another account/,
        )
    })
})
