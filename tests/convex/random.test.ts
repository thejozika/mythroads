import { convexTest } from 'convex-test'
import { describe, expect, test } from 'vitest'
import { api } from '../../convex/_generated/api'
import { drawBounded, normalizeSeed } from '../../convex/generated/random.generated'
import schema from '../../convex/schema'

const modules = import.meta.glob(['../../convex/**/*.ts', '!../../convex/**/*.test.ts'])
const owner = {
    subject: 'owner',
    issuer: 'https://auth.dicebound.test',
    tokenIdentifier: 'https://auth.dicebound.test|owner',
}

describe('Lean-generated seeded randomness', () => {
    test('the same room seed produces the same room code in isolated worlds', async () => {
        const create = async () => {
            const t = convexTest(schema, modules)
            return await t.withIdentity(owner).mutation(api.game.dispatch, {
                event: { type: 'room.create', subjects: {}, data: { seed: 20260910 } },
            })
        }

        expect(await create()).toEqual(await create())
    })

    test('movement rolls consume and persist the room random stream', async () => {
        const t = convexTest(schema, modules)
        const seed = 73
        const initialState = normalizeSeed(seed)
        const { roomId, playerId } = await t.run(async (ctx) => {
            const roomId = await ctx.db.insert('rooms', {
                code: 'SEED',
                hostAuthId: owner.tokenIdentifier,
                status: 'playing',
                remainingMoves: 0,
                message: 'Roll',
                round: 1,
                phase: 'awaitingRoll',
                activePlayerId: undefined,
                rngState: initialState,
                rngCounter: 0,
            })
            const playerId = await ctx.db.insert('players', {
                roomId,
                authId: owner.tokenIdentifier,
                name: 'Seeder',
                color: '#4bd3c2',
                position: 0,
                gold: 10,
                hp: 10,
                maxHp: 10,
                attack: 2,
                dice: [4, 6],
                joinedAt: 1,
            })
            await ctx.db.patch(roomId, { activePlayerId: playerId })
            return { roomId, playerId }
        })

        const first = drawBounded(initialState, 4)
        const second = drawBounded(first.state, 6)
        await t.withIdentity(owner).mutation(api.game.dispatch, {
            event: { type: 'movement.roll', subjects: { roomId, playerId }, data: {} },
        })
        const room = await t.run(async (ctx) => await ctx.db.get(roomId))

        expect(room?.lastRoll).toEqual([first.value + 1, second.value + 1])
        expect(room?.rngState).toBe(second.state)
        expect(room?.rngCounter).toBe(2)
    })
})
