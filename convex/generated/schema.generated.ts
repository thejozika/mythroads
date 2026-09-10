/** Generated from proofs/Mythroads/Game/Schema.lean for Convex 1.45.0. Do not edit by hand. */
import { defineSchema, defineTable } from 'convex/server'
import { v } from 'convex/values'
import { dispatchResultValidator, gameEventValidator } from '../events/validators'

export const appSchema = defineSchema({
    rooms: defineTable(
        v.object({
            code: v.string(),
            hostAuthId: v.optional(v.string()),
            status: v.union(v.literal('lobby'), v.literal('playing'), v.literal('finished')),
            activePlayerId: v.optional(v.id('players')),
            remainingMoves: v.number(),
            lastRoll: v.optional(v.array(v.number())),
            message: v.string(),
            round: v.number(),
            phase: v.optional(
                v.union(
                    v.literal('awaitingRoll'),
                    v.literal('moving'),
                    v.literal('revealingEncounter'),
                    v.literal('shopping'),
                    v.literal('combatAttack'),
                    v.literal('combatDefend'),
                ),
            ),
            activeEncounterId: v.optional(v.id('encounters')),
            activeCombatId: v.optional(v.id('combats')),
            shopKind: v.optional(
                v.union(
                    v.literal('armoury'),
                    v.literal('jeweller'),
                    v.literal('weapons'),
                    v.literal('items'),
                    v.literal('magic'),
                ),
            ),
            rngState: v.optional(v.number()),
            rngCounter: v.optional(v.number()),
        }),
    ).index('by_code', ['code']),
    players: defineTable(
        v.object({
            roomId: v.id('rooms'),
            authId: v.optional(v.string()),
            name: v.string(),
            color: v.string(),
            position: v.number(),
            previousPosition: v.optional(v.number()),
            gold: v.number(),
            hp: v.number(),
            maxHp: v.number(),
            attack: v.number(),
            defense: v.optional(v.number()),
            magic: v.optional(v.number()),
            athletics: v.optional(v.number()),
            agility: v.optional(v.number()),
            dice: v.array(v.number()),
            joinedAt: v.number(),
        }),
    )
        .index('by_room', ['roomId'])
        .index('by_room_and_authId', ['roomId', 'authId']),
    encounters: defineTable(
        v.object({
            roomId: v.id('rooms'),
            playerId: v.id('players'),
            spaceId: v.number(),
            kind: v.union(v.literal('combat'), v.literal('event')),
            outcomeId: v.string(),
            title: v.string(),
            description: v.string(),
            goldDelta: v.number(),
            hpDelta: v.number(),
            wheelIndex: v.number(),
            status: v.union(v.literal('revealing'), v.literal('resolved')),
            createdAt: v.number(),
        }),
    ).index('by_roomId', ['roomId']),
    combats: defineTable(
        v.object({
            roomId: v.id('rooms'),
            playerId: v.id('players'),
            spaceId: v.number(),
            enemyName: v.string(),
            enemyElement: v.union(
                v.literal('fire'),
                v.literal('water'),
                v.literal('wind'),
                v.literal('earth'),
            ),
            enemyHp: v.number(),
            enemyMaxHp: v.number(),
            enemyAttack: v.number(),
            enemyDefense: v.optional(v.number()),
            enemyMagic: v.optional(v.number()),
            enemyAthletics: v.optional(v.number()),
            enemyAgility: v.optional(v.number()),
            enemyDefensePenalty: v.optional(v.number()),
            enemyMagicPenalty: v.optional(v.number()),
            enemyAthleticsPenalty: v.optional(v.number()),
            enemyAgilityPenalty: v.optional(v.number()),
            playerDefensePenalty: v.optional(v.number()),
            playerMagicPenalty: v.optional(v.number()),
            playerAthleticsPenalty: v.optional(v.number()),
            playerAgilityPenalty: v.optional(v.number()),
            reward: v.number(),
            round: v.number(),
            phase: v.union(v.literal('attack'), v.literal('defend'), v.literal('resolved')),
            lastAttack: v.optional(v.string()),
            lastGuard: v.optional(v.string()),
            lastDamage: v.optional(v.number()),
            message: v.string(),
            createdAt: v.number(),
        }),
    ).index('by_roomId', ['roomId']),
    roomSelections: defineTable(
        v.object({
            roomId: v.id('rooms'),
            playerId: v.id('players'),
            destination: v.number(),
            path: v.optional(v.array(v.number())),
            updatedAt: v.number(),
        }),
    ).index('by_roomId', ['roomId']),
    playerItems: defineTable(
        v.object({
            playerId: v.id('players'),
            itemId: v.string(),
            equippedSlot: v.optional(
                v.union(
                    v.literal('weapon'),
                    v.literal('helmet'),
                    v.literal('body'),
                    v.literal('gloves'),
                    v.literal('boots'),
                    v.literal('cape'),
                    v.literal('amulet'),
                    v.literal('ringLeft'),
                    v.literal('ringRight'),
                    v.literal('offensiveMagic'),
                    v.literal('defensiveMagic'),
                ),
            ),
            purchasedAt: v.number(),
        }),
    ).index('by_playerId', ['playerId']),
    gameEvents: defineTable(
        v.union(
            v.object({ type: v.string(), subjects: v.any(), data: v.any(), createdAt: v.number() }),
            v.object({
                eventId: v.string(),
                commandId: v.optional(v.string()),
                schemaVersion: v.literal(1),
                roomId: v.optional(v.id('rooms')),
                actorPlayerId: v.optional(v.id('players')),
                authority: v.object({
                    mode: v.union(
                        v.literal('prototypePlayerId'),
                        v.literal('authenticated'),
                        v.literal('developmentBypass'),
                    ),
                    actorPlayerId: v.optional(v.id('players')),
                    actorAuthId: v.optional(v.string()),
                }),
                event: gameEventValidator,
                result: dispatchResultValidator,
                createdAt: v.number(),
            }),
        ),
    )
        .index('by_createdAt', ['createdAt'])
        .index('by_commandId', ['commandId'])
        .index('by_roomId_and_createdAt', ['roomId', 'createdAt']),
    roomCameras: defineTable(
        v.object({
            roomId: v.id('rooms'),
            mode: v.union(v.literal('follow'), v.literal('free')),
            targetX: v.number(),
            targetZ: v.number(),
            distance: v.number(),
            updatedAt: v.number(),
        }),
    ).index('by_roomId', ['roomId']),
})

export default appSchema
