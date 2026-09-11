/** Generated from proofs/Mythroads/Backend/Aggregate/Persist.lean. Do not edit by hand. */
import { ConvexError } from 'convex/values'
import type { Camera, Effect, PlayerState, Selection, State } from '../../../shared/engine.system'
import type { Id } from '../../_generated/dataModel'
import type { MutationCtx } from '../../_generated/server'
import {
    combatColumns,
    encounterColumns,
    heroColumns,
    movesColumn,
    phaseColumn,
    slotColumn,
    statusColumn,
} from './rows.generated'

export type SaveReport = { playerId: Id<'players'> | null }

async function insertHero(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    hero: PlayerState,
): Promise<Id<'players'>> {
    const createdAt = Date.now()
    const playerId = await ctx.db.insert('players', {
        roomId: roomId,
        ...heroColumns(hero),
        joinedAt: createdAt,
    })
    for (const owned of hero.items) {
        await ctx.db.insert('playerItems', {
            playerId: playerId,
            itemId: owned.itemId,
            equippedSlot: slotColumn(owned.equippedSlot),
            purchasedAt: createdAt,
        })
    }
    return playerId
}

async function syncItems(
    ctx: MutationCtx,
    playerId: Id<'players'>,
    previous: PlayerState,
    hero: PlayerState,
): Promise<void> {
    for (const item of hero.items) {
        const existing = previous.items.find((candidate) => candidate.rowId === item.rowId)
        if (!existing) {
            await ctx.db.insert('playerItems', {
                playerId: playerId,
                itemId: item.itemId,
                equippedSlot: slotColumn(item.equippedSlot),
                purchasedAt: Date.now(),
            })
        } else {
            if (slotColumn(existing.equippedSlot) !== slotColumn(item.equippedSlot)) {
                await ctx.db.patch('playerItems', item.rowId as Id<'playerItems'>, {
                    equippedSlot: slotColumn(item.equippedSlot),
                })
            }
        }
    }
}

async function persistHero(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    before: State,
    after: State,
    id: string,
): Promise<Id<'players'>> {
    const hero = after.players.find((candidate) => candidate.id === id)
    if (!hero) {
        throw new ConvexError('That hero does not exist.')
    }
    const previous = before.players.find((candidate) => candidate.id === id)
    if (!previous) {
        return await insertHero(ctx, roomId, hero)
    }
    const playerId = hero.id as Id<'players'>
    await ctx.db.patch('players', playerId, heroColumns(hero))
    await syncItems(ctx, playerId, previous, hero)
    return playerId
}

async function upsertSelection(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    selection: Selection,
): Promise<void> {
    const existing = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const value = {
        roomId: roomId,
        playerId: selection.playerId as Id<'players'>,
        destination: selection.destination,
        path: selection.path,
        updatedAt: Date.now(),
    }
    if (existing) {
        await ctx.db.replace(existing._id, value)
        return
    }
    await ctx.db.insert('roomSelections', value)
}

async function dropSelection(ctx: MutationCtx, roomId: Id<'rooms'>): Promise<void> {
    const existing = await ctx.db
        .query('roomSelections')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    if (existing) {
        await ctx.db.delete(existing._id)
    }
}

async function upsertCamera(ctx: MutationCtx, roomId: Id<'rooms'>, camera: Camera): Promise<void> {
    const existing = await ctx.db
        .query('roomCameras')
        .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
        .first()
    const value = {
        mode: camera.free ? ('free' as const) : ('follow' as const),
        targetX: camera.targetX / 100,
        targetZ: camera.targetZ / 100,
        distance: camera.distance,
        updatedAt: Date.now(),
    }
    if (existing) {
        await ctx.db.patch(existing._id, value)
        return
    }
    await ctx.db.insert('roomCameras', { roomId: roomId, ...value })
}

export async function saveState(
    ctx: MutationCtx,
    roomId: Id<'rooms'>,
    before: State,
    after: State,
    effects: Effect[],
): Promise<SaveReport> {
    const room = await ctx.db.get('rooms', roomId)
    if (!room) {
        throw new ConvexError('That room does not exist.')
    }
    let combatId = room.activeCombatId
    let encounterId = room.activeEncounterId
    const report: SaveReport = { playerId: null }
    for (const effect of effects) {
        switch (effect._) {
            case 'persistPlayer': {
                report.playerId = await persistHero(ctx, roomId, before, after, effect.id)
                break
            }
            case 'persistCombat': {
                const columns = combatColumns(roomId, effect.battle, effect.stage)
                if (combatId) {
                    await ctx.db.patch(combatId, columns)
                } else {
                    combatId = await ctx.db.insert('combats', { ...columns, createdAt: Date.now() })
                }
                break
            }
            case 'persistEncounter': {
                const columns = encounterColumns(roomId, effect.drawn)
                if (encounterId) {
                    await ctx.db.patch(encounterId, columns)
                } else {
                    encounterId = await ctx.db.insert('encounters', {
                        ...columns,
                        createdAt: Date.now(),
                    })
                }
                break
            }
            case 'persistSelection': {
                await upsertSelection(ctx, roomId, effect.selection)
                break
            }
            case 'clearSelection': {
                await dropSelection(ctx, roomId)
                break
            }
            case 'persistCamera': {
                await upsertCamera(ctx, roomId, effect.camera)
                break
            }
            case 'persistRoom': {
                const active = after.players[after.turn]
                await ctx.db.patch('rooms', roomId, {
                    code: after.code,
                    hostAuthId: after.host === '' ? undefined : after.host,
                    status: statusColumn(after.phase),
                    activePlayerId:
                        after.phase._ === 'lobby' || !active
                            ? undefined
                            : (active.id as Id<'players'>),
                    remainingMoves: movesColumn(after.phase),
                    lastRoll: after.lastRoll.length === 0 ? undefined : after.lastRoll,
                    message: after.message,
                    round: after.round,
                    phase: phaseColumn(after.phase),
                    activeEncounterId: after.phase._ === 'encounter' ? encounterId : undefined,
                    activeCombatId: after.phase._ === 'combat' ? combatId : undefined,
                    shopKind: after.phase._ === 'shop' ? after.phase.kind._ : undefined,
                    rngState: after.rng,
                    rngCounter: after.rngCounter,
                    eventVersion: after.version,
                })
                break
            }
            case 'appendLog': {
                break
            }
            case 'notify': {
                break
            }
        }
    }
    return report
}

export async function insertRoom(
    ctx: MutationCtx,
    after: State,
    code: string,
    rngState: number,
    rngCounter: number,
): Promise<void> {
    await ctx.db.insert('rooms', {
        code: code,
        hostAuthId: after.host === '' ? undefined : after.host,
        status: 'lobby' as const,
        remainingMoves: 0,
        message: after.message,
        round: after.round,
        phase: 'awaitingRoll' as const,
        rngState: rngState,
        rngCounter: rngCounter,
        eventVersion: after.version,
    })
}
