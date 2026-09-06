import { ConvexError } from 'convex/values'
import { getNode } from '../shared/board.system'
import type { Id } from './_generated/dataModel'
import type { MutationCtx } from './_generated/server'

type CameraSubjects = { roomId: Id<'rooms'>; playerId: Id<'players'> }

async function cameraForRoom(ctx: MutationCtx, roomId: Id<'rooms'>) {
    return await ctx.db
        .query('roomCameras')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .unique()
}

async function requireCameraControl(ctx: MutationCtx, subjects: CameraSubjects) {
    const [room, player] = await Promise.all([
        ctx.db.get(subjects.roomId),
        ctx.db.get(subjects.playerId),
    ])
    if (!room || !player || player.roomId !== room._id || room.activePlayerId !== player._id) {
        throw new ConvexError('Only the active player can control the camera.')
    }
    return { room, player, camera: await cameraForRoom(ctx, room._id) }
}

export async function toggleCamera(ctx: MutationCtx, subjects: CameraSubjects) {
    const { room, player, camera } = await requireCameraControl(ctx, subjects)
    if (camera) {
        const node = getNode(player.position)
        await ctx.db.patch(camera._id, {
            mode: camera.mode === 'free' ? 'follow' : 'free',
            targetX: node.x,
            targetZ: node.z,
            updatedAt: Date.now(),
        })
        return
    }
    const node = getNode(player.position)
    await ctx.db.insert('roomCameras', {
        roomId: room._id,
        mode: 'free',
        targetX: node.x,
        targetZ: node.z,
        distance: 8,
        updatedAt: Date.now(),
    })
}

export async function moveCamera(
    ctx: MutationCtx,
    subjects: CameraSubjects,
    direction: 'up' | 'down' | 'left' | 'right',
) {
    const { camera } = await requireCameraControl(ctx, subjects)
    if (camera?.mode !== 'free') throw new ConvexError('Free camera is not active.')
    const delta = 0.9
    const targetX =
        camera.targetX + (direction === 'left' ? -delta : direction === 'right' ? delta : 0)
    const targetZ =
        camera.targetZ + (direction === 'up' ? -delta : direction === 'down' ? delta : 0)
    await ctx.db.patch(camera._id, {
        targetX: Math.max(-7, Math.min(7, targetX)),
        targetZ: Math.max(-5.5, Math.min(5.5, targetZ)),
        updatedAt: Date.now(),
    })
}

export async function zoomCamera(ctx: MutationCtx, subjects: CameraSubjects, delta: -1 | 1) {
    const { camera } = await requireCameraControl(ctx, subjects)
    if (camera?.mode !== 'free') throw new ConvexError('Free camera is not active.')
    await ctx.db.patch(camera._id, {
        distance: Math.max(5, Math.min(15, camera.distance + delta)),
        updatedAt: Date.now(),
    })
}
