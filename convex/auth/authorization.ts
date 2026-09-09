import { ConvexError } from 'convex/values'
import type { Id } from '../_generated/dataModel'
import type { MutationCtx, QueryCtx } from '../_generated/server'
import type { GameEvent } from '../events/validators'

declare const process: { env: Record<string, string | undefined> }

type AuthContext = Pick<MutationCtx | QueryCtx, 'auth' | 'db'>

export const developmentAuthBypass = () => process.env.DEV_NO_AUTH === 'true'

export async function requireAuthId(ctx: AuthContext) {
    const identity = await ctx.auth.getUserIdentity()
    if (identity) return identity.tokenIdentifier
    if (developmentAuthBypass()) return null
    throw new ConvexError('Sign in to continue.')
}

export async function requirePlayerOwner(ctx: AuthContext, playerId: Id<'players'>) {
    const authId = await requireAuthId(ctx)
    const player = await ctx.db.get(playerId)
    if (!player) throw new ConvexError('That hero does not exist.')
    if (!developmentAuthBypass() && player.authId !== authId) {
        throw new ConvexError('That hero belongs to another account.')
    }
    return { authId, player }
}

export async function authorizeGameEvent(ctx: MutationCtx, event: GameEvent) {
    const authId = await requireAuthId(ctx)
    if (developmentAuthBypass()) return authId
    if (event.type === 'room.create' || event.type === 'player.join') return authId
    if (event.type === 'game.start') {
        const room = await ctx.db.get(event.subjects.roomId)
        if (!room || room.hostAuthId !== authId) throw new ConvexError('Only the host can start.')
        return authId
    }
    if ('playerId' in event.subjects) {
        await requirePlayerOwner(ctx, event.subjects.playerId)
        return authId
    }
    throw new ConvexError('This command has no authenticated actor.')
}
