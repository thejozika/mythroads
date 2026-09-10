/** Generated from proofs/Mythroads/Backend/Room/Queries.lean. Do not edit by hand. */
import { v } from 'convex/values'
import type { Doc, Id } from '../_generated/dataModel'
import type { QueryCtx } from '../_generated/server'
import { developmentAuthBypass, requireAuthId, requirePlayerOwner } from '../auth/authorization'
import schema from '../schema'

type PublicPlayer = {
    _id: Id<'players'>
    name: string
    color: string
    position: number
    previousPosition?: number
    joinedAt: number
}
type ActiveState = {
    encounter: Doc<'encounters'> | null
    combat: Doc<'combats'> | null
    selection: Doc<'roomSelections'> | null
    camera: Doc<'roomCameras'> | null
}

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

function roomView(
    room: Doc<'rooms'>,
): Omit<Doc<'rooms'>, 'hostAuthId' | 'rngState' | 'rngCounter'> {
    const { hostAuthId, rngCounter, rngState, ...view } = room
    void hostAuthId
    void rngCounter
    void rngState
    return view
}

function playerView(player: Doc<'players'>): Omit<Doc<'players'>, 'authId'> {
    const { authId, ...view } = player
    void authId
    return view
}

function publicPlayer(player: Doc<'players'>): PublicPlayer {
    return {
        _id: player._id,
        name: player.name,
        color: player.color,
        position: player.position,
        previousPosition: player.previousPosition,
        joinedAt: player.joinedAt,
    }
}

async function activeState(ctx: QueryCtx, room: Doc<'rooms'>): Promise<ActiveState> {
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
    return { encounter: encounter, combat: combat, selection: selection, camera: camera }
}

export const displayByCodeDefinition = {
    args: { code: v.string() },
    returns: v.union(
        v.null(),
        v.object({
            room: roomViewValidator,
            players: v.array(publicPlayerValidator),
            canStart: v.boolean(),
            encounter: v.union(v.null(), schema.doc('encounters')),
            combat: v.union(v.null(), schema.doc('combats')),
            selection: v.union(v.null(), schema.doc('roomSelections')),
            camera: v.union(v.null(), schema.doc('roomCameras')),
        }),
    ),
    handler: async (ctx: QueryCtx, { code }: { code: string }) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (lookup) => lookup.eq('code', code.toUpperCase()))
            .unique()
        if (!room) {
            return null
        }
        const players = await ctx.db
            .query('players')
            .withIndex('by_room', (lookup) => lookup.eq('roomId', room._id))
            .take(4)
        const identity = await ctx.auth.getUserIdentity()
        const active = await activeState(ctx, room)
        return {
            room: roomView(room),
            players: players.sort((a, b) => a.joinedAt - b.joinedAt).map(publicPlayer),
            canStart:
                developmentAuthBypass() ||
                Boolean(identity && room.hostAuthId === identity.tokenIdentifier),
            encounter: active.encounter,
            combat: active.combat,
            selection: active.selection,
            camera: active.camera,
        }
    },
}

export const controllerByCodeDefinition = {
    args: { code: v.string(), playerId: v.id('players') },
    returns: v.union(
        v.null(),
        v.object({
            room: roomViewValidator,
            players: v.array(playerViewValidator),
            encounter: v.union(v.null(), schema.doc('encounters')),
            combat: v.union(v.null(), schema.doc('combats')),
            selection: v.union(v.null(), schema.doc('roomSelections')),
            camera: v.union(v.null(), schema.doc('roomCameras')),
        }),
    ),
    handler: async (
        ctx: QueryCtx,
        { code, playerId }: { code: string; playerId: Id<'players'> },
    ) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (lookup) => lookup.eq('code', code.toUpperCase()))
            .unique()
        if (!room) {
            return null
        }
        const ownership = await requirePlayerOwner(ctx, playerId)
        const player = ownership.player
        if (player.roomId !== room._id) {
            return null
        }
        const active = await activeState(ctx, room)
        return {
            room: roomView(room),
            players: [playerView(player)],
            encounter: active.encounter,
            combat: active.combat,
            selection: active.selection,
            camera: active.camera,
        }
    },
}

export const myPlayerByCodeDefinition = {
    args: { code: v.string() },
    returns: v.union(v.null(), v.id('players')),
    handler: async (ctx: QueryCtx, { code }: { code: string }) => {
        const authId = await requireAuthId(ctx)
        if (!authId) {
            return null
        }
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (lookup) => lookup.eq('code', code.toUpperCase()))
            .unique()
        if (!room) {
            return null
        }
        const player = await ctx.db
            .query('players')
            .withIndex('by_room_and_authId', (lookup) =>
                lookup.eq('roomId', room._id).eq('authId', authId),
            )
            .unique()
        return player?._id ?? null
    },
}
