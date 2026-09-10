/** Generated from proofs/Mythroads/Backend/Camera.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import { getNode } from '../../shared/board.system'
import type { Doc, Id } from '../_generated/dataModel'
import type { MutationCtx } from '../_generated/server'

async function cameraForRoom(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
): Promise<Doc<'roomCameras'> | null> {
    return await ctx.db
        .query('roomCameras')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .unique()
}

async function requireCameraControl(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
): Promise<{ room: Doc<'rooms'>; player: Doc<'players'>; camera: Doc<'roomCameras'> | null }> {
    const room = await ctx.db.get(subjects.roomId)
    const player = await ctx.db.get(subjects.playerId)
    if (!room || !player || player.roomId !== room._id || room.activePlayerId !== player._id) {
        throw new ConvexError('Only the active player can control the camera.')
    }
    const camera = await cameraForRoom(ctx, room._id)
    return { room: room, player: player, camera: camera }
}

export async function toggleCamera(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
): Promise<void> {
    const control = await requireCameraControl(ctx, subjects)
    const node = getNode(control.player.position)
    if (control.camera) {
        await ctx.db.patch(control.camera._id, {
            mode: control.camera.mode === 'free' ? 'follow' : 'free',
            targetX: node.x,
            targetZ: node.z,
            updatedAt: Date.now(),
        })
        return
    }
    await ctx.db.insert('roomCameras', {
        roomId: control.room._id,
        mode: 'free',
        targetX: node.x,
        targetZ: node.z,
        distance: 8,
        updatedAt: Date.now(),
    })
}

export async function moveCamera(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    direction: 'up' | 'down' | 'left' | 'right',
): Promise<void> {
    const control = await requireCameraControl(ctx, subjects)
    const camera = control.camera
    if (!camera || camera.mode !== 'free') {
        throw new ConvexError('Free camera is not active.')
    }
    const targetX =
        camera.targetX + (direction === 'left' ? -(9 / 10) : direction === 'right' ? 9 / 10 : 0)
    const targetZ =
        camera.targetZ + (direction === 'up' ? -(9 / 10) : direction === 'down' ? 9 / 10 : 0)
    await ctx.db.patch(camera._id, {
        targetX: Math.max(-7, Math.min(7, targetX)),
        targetZ: Math.max(-(55 / 10), Math.min(55 / 10, targetZ)),
        updatedAt: Date.now(),
    })
}

export async function zoomCamera(
    ctx: MutationCtx,
    subjects: { roomId: Id<'rooms'>; playerId: Id<'players'> },
    delta: -1 | 1,
): Promise<void> {
    const control = await requireCameraControl(ctx, subjects)
    const camera = control.camera
    if (!camera || camera.mode !== 'free') {
        throw new ConvexError('Free camera is not active.')
    }
    await ctx.db.patch(camera._id, {
        distance: Math.max(5, Math.min(15, camera.distance + delta)),
        updatedAt: Date.now(),
    })
}
