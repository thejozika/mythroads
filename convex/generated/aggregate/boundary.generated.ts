/** Generated from proofs/Mythroads/Backend/Aggregate/Boundary.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import {
    Error_message,
    Event_authority,
    Lobby_roomCode,
    type State,
    step,
} from '../../../shared/engine.system'
import type { Id } from '../../_generated/dataModel'
import type { MutationCtx } from '../../_generated/server'
import type { DispatchResult, GameEvent } from '../../events/validators'
import { envelopeFrom, eventFrom, subjectOf, wireNat } from './envelope.generated'
import { emptyState, loadState } from './load.generated'
import { insertRoom, saveState } from './persist.generated'

async function roomIdForEvent(ctx: MutationCtx, event: GameEvent): Promise<Id<'rooms'>> {
    if (event.type === 'player.join') {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (query) => query.eq('code', event.subjects.code.toUpperCase()))
            .unique()
        if (!room) {
            throw new ConvexError('That room does not exist.')
        }
        return room._id
    }
    if (event.type === 'inventory.equip') {
        const player = await ctx.db.get('players', event.subjects.playerId)
        if (!player) {
            throw new ConvexError('That hero does not exist.')
        }
        return player.roomId
    }
    if ('roomId' in event.subjects) {
        return event.subjects.roomId
    }
    throw new ConvexError('That room does not exist.')
}

function actorFor(event: GameEvent, actorAuthId: string | null, before: State): string {
    if (actorAuthId) {
        return actorAuthId
    }
    const authority = Event_authority(eventFrom(event, 0))
    if (authority._ === 'roomHost') {
        return before.host
    }
    if (authority._ === 'playerOwner') {
        const subject = subjectOf(event)
        const hero =
            subject._ === 'some'
                ? before.players.find((candidate) => candidate.id === subject.val)
                : undefined
        return hero ? hero.owner : ''
    }
    return ''
}

async function requireRipeEncounter(ctx: MutationCtx, event: GameEvent): Promise<void> {
    if (event.type !== 'encounter.resolve') {
        return
    }
    const encounter = await ctx.db.get('encounters', event.subjects.encounterId)
    if (
        !encounter ||
        encounter.roomId !== event.subjects.roomId ||
        encounter.playerId !== event.subjects.playerId ||
        encounter.status !== 'revealing' ||
        Date.now() - encounter.createdAt < 2200
    ) {
        throw new ConvexError('This encounter cannot be resolved now.')
    }
}

async function freeRoomCode(
    ctx: MutationCtx,
    after: State,
): Promise<{ code: string; rngState: number; rngCounter: number }> {
    let code = after.code
    let rngState = after.rng
    let rngCounter = after.rngCounter
    let attempts = 0
    while (
        await ctx.db
            .query('rooms')
            .withIndex('by_code', (query) => query.eq('code', code))
            .unique()
    ) {
        if (attempts >= 32) {
            throw new ConvexError('Could not allocate a room code.')
        }
        attempts = attempts + 1
        const drawn = Lobby_roomCode(rngState)
        code = drawn.fst
        rngState = drawn.snd
        rngCounter = rngCounter + 4
    }
    return { code, rngState, rngCounter }
}

async function createRoom(
    ctx: MutationCtx,
    event: GameEvent,
    actorAuthId: string | null,
): Promise<DispatchResult> {
    const before = emptyState()
    const requested =
        event.type === 'room.create' && event.data.seed !== undefined
            ? wireNat(event.data.seed)
            : undefined
    const seed = requested ?? Date.now()
    const envelope = envelopeFrom(event, actorFor(event, actorAuthId, before), seed)
    const outcome = step(before, envelope)
    if (outcome._ === 'error') {
        throw new ConvexError(Error_message(outcome.a, envelope.event))
    }
    const after = outcome.a.fst
    const free = await freeRoomCode(ctx, after)
    await insertRoom(ctx, after, free.code, free.rngState, free.rngCounter)
    return { kind: 'room.created', code: free.code }
}

export async function applyGameEvent(
    ctx: MutationCtx,
    event: GameEvent,
    actorAuthId: string | null,
): Promise<DispatchResult> {
    if (event.type === 'room.create') {
        return await createRoom(ctx, event, actorAuthId)
    }
    await requireRipeEncounter(ctx, event)
    const roomId = await roomIdForEvent(ctx, event)
    const before = await loadState(ctx, roomId)
    const envelope = envelopeFrom(event, actorFor(event, actorAuthId, before), 0)
    const outcome = step(before, envelope)
    if (outcome._ === 'error') {
        throw new ConvexError(Error_message(outcome.a, envelope.event))
    }
    const saved = await saveState(ctx, roomId, before, outcome.a.fst, outcome.a.snd)
    if (event.type === 'player.join') {
        if (!saved.playerId) {
            throw new ConvexError('Choose a hero name.')
        }
        return { kind: 'player.joined', playerId: saved.playerId }
    }
    return { kind: 'accepted' }
}
