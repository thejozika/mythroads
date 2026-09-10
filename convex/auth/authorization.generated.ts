/** Generated from proofs/Mythroads/Game/Events.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import type { Doc, Id } from '../_generated/dataModel'
import type { MutationCtx, QueryCtx } from '../_generated/server'
import type { GameEvent } from '../events/validators'

declare const process: { env: Record<string, string | undefined> }
type AuthContext = Pick<MutationCtx | QueryCtx, 'auth' | 'db'>

export function developmentAuthBypass(): boolean {
    return process.env.DEV_NO_AUTH === 'true'
}

export async function requireAuthId(ctx: AuthContext): Promise<string | null> {
    const identity = await ctx.auth.getUserIdentity()
    if (identity) {
        return identity.tokenIdentifier
    }
    if (developmentAuthBypass()) {
        return null
    }
    throw new ConvexError('Sign in to continue.')
}

export async function requirePlayerOwner(
    ctx: AuthContext,
    playerId: Id<'players'>,
): Promise<{ authId: string | null; player: Doc<'players'> }> {
    const authId = await requireAuthId(ctx)
    const player = await ctx.db.get(playerId)
    if (!player) {
        throw new ConvexError('That hero does not exist.')
    }
    if (!developmentAuthBypass() && player.authId !== authId) {
        throw new ConvexError('That hero belongs to another account.')
    }
    return { authId: authId, player: player }
}

export async function authorizeGameEvent(
    ctx: MutationCtx,
    event: GameEvent,
): Promise<string | null> {
    const authId = await requireAuthId(ctx)
    if (developmentAuthBypass()) {
        return authId
    }
    switch (event.type) {
        case 'room.create': {
            return authId
        }
        case 'player.join': {
            return authId
        }
        case 'game.start': {
            const room = await ctx.db.get(event.subjects.roomId)
            if (!room || room.hostAuthId !== authId) {
                throw new ConvexError('Only the host can start.')
            }
            return authId
        }
        case 'movement.roll': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'movement.select': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'movement.cancel': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'movement.step': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'combat.attack': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'combat.guard': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'encounter.resolve': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'shop.buy': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'inventory.equip': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'shop.leave': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'camera.toggle': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'camera.move': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
        case 'camera.zoom': {
            await requirePlayerOwner(ctx, event.subjects.playerId)
            return authId
        }
    }
    throw new ConvexError('This command has no authenticated actor.')
}
