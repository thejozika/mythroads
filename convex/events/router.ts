import type { MutationCtx } from '../_generated/server'
import { moveCamera, toggleCamera, zoomCamera } from '../camera'
import { chooseAttack, chooseGuard } from '../combat'
import { resolveEncounter } from '../encounters'
import {
    cancelDestination,
    createRoom,
    joinRoom,
    movePlayer,
    rollMovement,
    selectDestination,
    startRoom,
} from '../rooms'
import { buyItem, equipItem, leaveShop } from '../shops'
import type { DispatchResult, GameEvent } from './validators.ts'

export async function routeGameEvent(
    ctx: MutationCtx,
    event: GameEvent,
    actorAuthId: string | null,
): Promise<DispatchResult> {
    switch (event.type) {
        case 'room.create':
            return {
                kind: 'room.created',
                code: await createRoom(ctx, actorAuthId ?? undefined, event.data.seed),
            }
        case 'player.join':
            return {
                kind: 'player.joined',
                playerId: await joinRoom(
                    ctx,
                    event.subjects.code,
                    event.data,
                    actorAuthId ?? undefined,
                ),
            }
        case 'game.start':
            await startRoom(ctx, event.subjects.roomId)
            break
        case 'movement.roll':
            await rollMovement(ctx, event.subjects)
            break
        case 'movement.select':
            await selectDestination(ctx, { ...event.subjects, ...event.data })
            break
        case 'movement.cancel':
            await cancelDestination(ctx, event.subjects)
            break
        case 'movement.step':
            await movePlayer(ctx, { ...event.subjects, ...event.data })
            break
        case 'combat.attack':
            await chooseAttack(ctx, event.subjects, event.data.attack)
            break
        case 'combat.guard':
            await chooseGuard(ctx, event.subjects, event.data.guard)
            break
        case 'encounter.resolve':
            await resolveEncounter(ctx, event.subjects)
            break
        case 'shop.buy':
            await buyItem(ctx, { ...event.subjects, ...event.data })
            break
        case 'inventory.equip':
            await equipItem(ctx, { ...event.subjects, ...event.data })
            break
        case 'shop.leave':
            await leaveShop(ctx, event.subjects)
            break
        case 'camera.toggle':
            await toggleCamera(ctx, event.subjects)
            break
        case 'camera.move':
            await moveCamera(ctx, event.subjects, event.data.direction)
            break
        case 'camera.zoom':
            await zoomCamera(ctx, event.subjects, event.data.delta)
            break
    }
    return { kind: 'accepted' }
}
