import { convexTest } from 'convex-test'
import { api } from '../../convex/_generated/api'
import type { Doc, Id } from '../../convex/_generated/dataModel'
import type { DispatchResult, GameEvent } from '../../convex/events/validators'
import schema from '../../convex/schema'

/**
 * Golden-master driver for the Convex gameplay surface. Every scenario goes through
 * `api.game.dispatch`; state is read straight from the tables so the tests pin storage
 * shape as well as behaviour.
 */
export const convexModules = import.meta.glob([
    '../../convex/**/*.ts',
    '!../../convex/**/*.test.ts',
])

const ISSUER = 'https://auth.dicebound.test'

export const COLORS = ['#4bd3c2', '#ef6b73', '#f2c14e', '#8f7bd8'] as const

export function identity(name: string) {
    return { subject: name, issuer: ISSUER, tokenIdentifier: `${ISSUER}|${name}` }
}

type ConvexHarness = ReturnType<typeof convexTest>

export type Scenario = {
    t: ConvexHarness
    code: string
    roomId: Id<'rooms'>
    /** Player ids in join order. */
    playerIds: Id<'players'>[]
    names: string[]
    dispatch: (as: string, event: GameEvent, commandId?: string) => Promise<DispatchResult>
    room: () => Promise<Doc<'rooms'>>
    players: () => Promise<Doc<'players'>[]>
    player: (index: number) => Promise<Doc<'players'>>
    combat: () => Promise<Doc<'combats'> | null>
    encounter: () => Promise<Doc<'encounters'> | null>
    selection: () => Promise<Doc<'roomSelections'> | null>
    camera: () => Promise<Doc<'roomCameras'> | null>
    items: (index: number) => Promise<Doc<'playerItems'>[]>
    gameEvents: () => Promise<Doc<'gameEvents'>[]>
    snapshots: () => Promise<Doc<'gameSnapshots'>[]>
    /** Overwrite the room random stream so a scenario can force a specific draw. */
    forceRng: (state: number) => Promise<void>
    patchPlayer: (index: number, patch: Partial<Doc<'players'>>) => Promise<void>
    patchRoom: (patch: Partial<Doc<'rooms'>>) => Promise<void>
    /** Backdate the live encounter past the 2200 ms reveal delay. */
    ripenEncounter: () => Promise<void>
}

export type ScenarioOptions = {
    seed: number
    /** Player names in join order; the first one is the host. */
    players: string[]
    start?: boolean
    /** Replace every hero's dice so each roll is exactly one step. */
    singleStepDice?: boolean
}

export async function createScenario(options: ScenarioOptions): Promise<Scenario> {
    const t = convexTest(schema, convexModules)
    const names = options.players
    const host = names[0]
    const created = await t.withIdentity(identity(host)).mutation(api.game.dispatch, {
        event: { type: 'room.create', subjects: {}, data: { seed: options.seed } },
    })
    if (created.kind !== 'room.created') throw new Error('room.create did not create a room')
    const code = created.code

    const playerIds: Id<'players'>[] = []
    for (const [index, name] of names.entries()) {
        const joined = await t.withIdentity(identity(name)).mutation(api.game.dispatch, {
            event: {
                type: 'player.join',
                subjects: { code },
                data: { name, color: COLORS[index % COLORS.length] },
            },
        })
        if (joined.kind !== 'player.joined') throw new Error('player.join did not create a hero')
        playerIds.push(joined.playerId)
    }

    const roomId = await t.run(async (ctx) => {
        const room = await ctx.db
            .query('rooms')
            .withIndex('by_code', (query) => query.eq('code', code))
            .unique()
        if (!room) throw new Error('room vanished')
        return room._id
    })

    const scenario = buildScenario(t, code, roomId, playerIds, names)
    if (options.singleStepDice) {
        for (const index of playerIds.keys()) await scenario.patchPlayer(index, { dice: [1] })
    }
    if (options.start !== false) {
        await scenario.dispatch(host, { type: 'game.start', subjects: { roomId }, data: {} })
    }
    return scenario
}

function buildScenario(
    t: ConvexHarness,
    code: string,
    roomId: Id<'rooms'>,
    playerIds: Id<'players'>[],
    names: string[],
): Scenario {
    const require = async <T>(value: Promise<T | null>, label: string): Promise<T> => {
        const resolved = await value
        if (!resolved) throw new Error(`${label} is missing`)
        return resolved
    }
    const firstByRoom = <Table extends 'combats' | 'encounters' | 'roomSelections' | 'roomCameras'>(
        table: Table,
    ) =>
        t.run(async (ctx) =>
            ctx.db
                .query(table)
                .withIndex('by_roomId', (query) => query.eq('roomId', roomId))
                .first(),
        )

    return {
        t,
        code,
        roomId,
        playerIds,
        names,
        dispatch: (as, event, commandId) =>
            t
                .withIdentity(identity(as))
                .mutation(api.game.dispatch, commandId ? { commandId, event } : { event }),
        room: () => require(t.run(async (ctx) => ctx.db.get(roomId)), 'room'),
        players: () =>
            t.run(async (ctx) => {
                const players = await ctx.db
                    .query('players')
                    .withIndex('by_room', (query) => query.eq('roomId', roomId))
                    .take(8)
                return players.sort((a, b) => a.joinedAt - b.joinedAt)
            }),
        player: (index) => require(t.run(async (ctx) => ctx.db.get(playerIds[index])), 'player'),
        combat: () => firstByRoom('combats'),
        encounter: () => firstByRoom('encounters'),
        selection: () => firstByRoom('roomSelections'),
        camera: () => firstByRoom('roomCameras'),
        items: (index) =>
            t.run(async (ctx) =>
                ctx.db
                    .query('playerItems')
                    .withIndex('by_playerId', (query) => query.eq('playerId', playerIds[index]))
                    .take(40),
            ),
        gameEvents: () =>
            t.run(async (ctx) => {
                const events = await ctx.db.query('gameEvents').withIndex('by_createdAt').take(500)
                return events
            }),
        snapshots: () =>
            t.run(async (ctx) =>
                ctx.db
                    .query('gameSnapshots')
                    .withIndex('by_roomId_and_version', (query) => query.eq('roomId', roomId))
                    .take(20),
            ),
        forceRng: (state) => t.run(async (ctx) => ctx.db.patch(roomId, { rngState: state })),
        patchPlayer: (index, patch) => t.run(async (ctx) => ctx.db.patch(playerIds[index], patch)),
        patchRoom: (patch) => t.run(async (ctx) => ctx.db.patch(roomId, patch)),
        ripenEncounter: () =>
            t.run(async (ctx) => {
                const room = await ctx.db.get(roomId)
                if (!room?.activeEncounterId) throw new Error('no live encounter')
                await ctx.db.patch(room.activeEncounterId, { createdAt: Date.now() - 5000 })
            }),
    }
}

/** Walk exactly one road from the hero's current space, using a one-sided die. */
export async function stepTo(
    scenario: Scenario,
    playerIndex: number,
    destination: number,
): Promise<void> {
    const as = scenario.names[playerIndex]
    const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[playerIndex] }
    const player = await scenario.player(playerIndex)
    await scenario.dispatch(as, { type: 'movement.roll', subjects, data: {} })
    await scenario.dispatch(as, {
        type: 'movement.select',
        subjects,
        data: { destination: player.position },
    })
    await scenario.dispatch(as, { type: 'movement.select', subjects, data: { destination } })
    await scenario.dispatch(as, { type: 'movement.step', subjects, data: { destination } })
}

/** Follow a chain of single-step moves, ending the turn between spaces when needed. */
export async function walkPath(
    scenario: Scenario,
    playerIndex: number,
    path: number[],
): Promise<void> {
    for (const destination of path) await stepTo(scenario, playerIndex, destination)
}

/**
 * Place a hero on `from` with a single pending move and travel one road to `to`.
 * Used to land on a chosen space kind without replaying a whole turn order.
 */
export async function teleportStep(
    scenario: Scenario,
    playerIndex: number,
    from: number,
    to: number,
): Promise<void> {
    const as = scenario.names[playerIndex]
    const subjects = { roomId: scenario.roomId, playerId: scenario.playerIds[playerIndex] }
    await scenario.patchPlayer(playerIndex, { position: from, previousPosition: undefined })
    await scenario.patchRoom({
        activePlayerId: scenario.playerIds[playerIndex],
        phase: 'moving',
        remainingMoves: 1,
        activeCombatId: undefined,
        activeEncounterId: undefined,
        shopKind: undefined,
    })
    await scenario.dispatch(as, { type: 'movement.select', subjects, data: { destination: from } })
    await scenario.dispatch(as, { type: 'movement.select', subjects, data: { destination: to } })
    await scenario.dispatch(as, { type: 'movement.step', subjects, data: { destination: to } })
}
