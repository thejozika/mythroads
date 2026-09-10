import { v } from 'convex/values'
import type { Doc } from '../_generated/dataModel'
import { query, type QueryCtx } from '../_generated/server'
import { developmentAuthBypass, requireAuthId, requirePlayerOwner } from '../auth/authorization'
import schema from '../schema'

const roomViewValidator = schema.doc('rooms').omit('hostAuthId', 'rngState', 'rngCounter')
const playerViewValidator = schema.doc('players').omit('authId')
const publicPlayerValidator = v.object({
    _id: v.id('players'),
    name: v.string(),
    color: v.string(),
    position: v.number(),
    previousPosition: v.optional(v.number()),
    joinedAt: v.number(),
})

function roomView(room: Doc<'rooms'>) {
    const { hostAuthId, rngCounter, rngState, ...view } = room
    void hostAuthId
    void rngCounter
    void rngState
    return view
}

function playerView(player: Doc<'players'>) {
    const { authId, ...view } = player
    void authId
    return view
}

function publicPlayer(player: Doc<'players'>) {
    return {
        _id: player._id,
        name: player.name,
        color: player.color,
        position: player.position,
        ...(player.previousPosition === undefined
            ? {}
            : { previousPosition: player.previousPosition }),
        joinedAt: player.joinedAt,
    }
}

async function activeState(ctx: QueryCtx, room: Doc<'rooms'>) {
    const encounter = room.activeEncounterId ? await ctx.db.get(room.activeEncounterId) : null
    const combat = room.activeCombatId ? await ctx.db.get(room.activeCombatId) : null
    const selection = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (lookup) => lookup.eq('roomId', room._id))
        .first()
    const camera = await ctx.db
        .query('roomCameras')
        .withIndex('by_roomId', (lookup) => lookup.eq('roomId', room._id))
        .unique()
    return { encounter, combat, selection, camera }
}

const activeValidators = {
    encounter: v.union(v.null(), schema.doc('encounters')),
    combat: v.union(v.null(), schema.doc('combats')),
    selection: v.union(v.null(), schema.doc('roomSelections')),
    camera: v.union(v.null(), schema.doc('roomCameras')),
}

export const displayByCode = query({
    args: { code: v.string() },
    returns: v.union(
        v.null(),
        v.object({
            room: roomViewValidator,
            players: v.array(publicPlayerValidator),
            canStart: v.boolean(),
            ...activeValidators,
        }),
    ),
    handler: async (ctx, { code }) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (lookup) => lookup.eq('code', code.toUpperCase()))
            .unique()
        if (!room) return null
        const players = await ctx.db
            .query('players')
            .withIndex('by_room', (lookup) => lookup.eq('roomId', room._id))
            .take(4)
        const identity = await ctx.auth.getUserIdentity()
        return {
            room: roomView(room),
            players: players.sort((a, b) => a.joinedAt - b.joinedAt).map(publicPlayer),
            canStart:
                developmentAuthBypass() ||
                Boolean(identity && room.hostAuthId === identity.tokenIdentifier),
            ...(await activeState(ctx, room)),
        }
    },
})

export const controllerByCode = query({
    args: { code: v.string(), playerId: v.id('players') },
    returns: v.union(
        v.null(),
        v.object({
            room: roomViewValidator,
            players: v.array(playerViewValidator),
            ...activeValidators,
        }),
    ),
    handler: async (ctx, { code, playerId }) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (lookup) => lookup.eq('code', code.toUpperCase()))
            .unique()
        if (!room) return null
        const { player } = await requirePlayerOwner(ctx, playerId)
        if (player.roomId !== room._id) return null
        return {
            room: roomView(room),
            players: [playerView(player)],
            ...(await activeState(ctx, room)),
        }
    },
})

export const myPlayerByCode = query({
    args: { code: v.string() },
    returns: v.union(v.null(), v.id('players')),
    handler: async (ctx, { code }) => {
        const authId = await requireAuthId(ctx)
        if (!authId) return null
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (lookup) => lookup.eq('code', code.toUpperCase()))
            .unique()
        if (!room) return null
        const player = await ctx.db
            .query('players')
            .withIndex('by_room_and_authId', (lookup) =>
                lookup.eq('roomId', room._id).eq('authId', authId),
            )
            .unique()
        return player?._id ?? null
    },
})
