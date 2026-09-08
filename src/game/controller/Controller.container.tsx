import { useMutation, useQuery } from 'convex/react'
import { useEffect, useState } from 'react'
import { api } from '../../../convex/_generated/api'
import type { Id } from '../../../convex/_generated/dataModel'
import { getNode, reachableRoutes } from '../../../shared/board.system'
import { directionalTargets } from '../../../shared/controller-input.system'
import type { ShopKind } from '../../../shared/item.system'
import { gameCommand } from '../game-event.util'
import { ControllerOverlays } from './ControllerOverlays.container'
import { Gamepad } from './Gamepad.component'
import { HeroStatus } from './HeroStatus.component'
import './controller.css'
import './controller-landscape.css'

export function Controller({ code, routePlayerId }: { code: string; routePlayerId?: string }) {
    const [inventoryOpen, setInventoryOpen] = useState(false)
    const [encounterReady, setEncounterReady] = useState(false)
    const state = useQuery(api.rooms.byCode, { code })
    const dispatch = useMutation(api.game.dispatch)
    const storedPlayerId = routePlayerId ?? localStorage.getItem(`dicebound:${code}`)
    const playerId = storedPlayerId as Id<'players'> | null
    const encounterId = state?.encounter?._id
    useEffect(() => {
        setEncounterReady(false)
        if (!encounterId) return
        const timer = window.setTimeout(() => setEncounterReady(true), 2400)
        return () => window.clearTimeout(timer)
    }, [encounterId])
    if (state === undefined) return <div className="loading">Finding your party…</div>
    if (!state || !playerId)
        return (
            <main className="phone-shell">
                <div className="controller-card">
                    <h1>Hero not found</h1>
                    <a className="button-link" href={`/join/${code}`}>
                        Join room
                    </a>
                </div>
            </main>
        )

    const player = state.players.find((candidate) => candidate._id === playerId)
    if (!player) return <div className="loading">This hero is no longer in the room.</div>
    const isActive = state.room.activePlayerId === playerId
    const phase = state.room.phase ?? (state.room.remainingMoves > 0 ? 'moving' : 'awaitingRoll')
    const canRoll = isActive && state.room.status === 'playing' && phase === 'awaitingRoll'
    const canResolve =
        isActive && phase === 'revealingEncounter' && Boolean(state.encounter) && encounterReady
    const cameraMode = state.camera?.mode === 'free'
    const selectedDestination =
        state.selection?.playerId === playerId ? state.selection.destination : undefined
    const routes =
        isActive && phase === 'moving' && state.room.remainingMoves > 0
            ? reachableRoutes(player.position, player.previousPosition, state.room.remainingMoves)
            : []
    const destinations = routes.map((route) => route.destination)
    const destinationMode = selectedDestination !== undefined
    const movementChoices = destinationMode
        ? directionalTargets(selectedDestination, destinations)
        : {}
    const moveDirections = Object.fromEntries(
        Object.entries(movementChoices).map(([direction, destination]) => [
            direction,
            {
                label: getNode(destination).label,
                kind: getNode(destination).kind,
                run: () =>
                    dispatch(
                        gameCommand({
                            type: 'movement.select',
                            subjects: { roomId: state.room._id, playerId },
                            data: { destination },
                        }),
                    ),
            },
        ]),
    )
    const cameraDirections = Object.fromEntries(
        (['up', 'down', 'left', 'right'] as const).map((direction) => [
            direction,
            {
                label: 'Free camera',
                kind: 'pan',
                run: () =>
                    dispatch(
                        gameCommand({
                            type: 'camera.move',
                            subjects: { roomId: state.room._id, playerId },
                            data: { direction },
                        }),
                    ),
            },
        ]),
    )
    const directions = cameraMode && isActive ? cameraDirections : moveDirections
    const beginDestinationMode =
        routes.length && !destinationMode
            ? () =>
                  dispatch(
                      gameCommand({
                          type: 'movement.select',
                          subjects: { roomId: state.room._id, playerId },
                          data: {
                              destination:
                                  routes.find((route) => route.destination !== player.position)
                                      ?.destination ?? routes[0].destination,
                          },
                      }),
                  )
            : undefined

    return (
        <main className="phone-shell" style={{ '--hero': player.color } as React.CSSProperties}>
            <div className="controller-card">
                <HeroStatus
                    code={code}
                    player={player}
                    active={isActive}
                    lastRoll={state.room.lastRoll}
                    remainingMoves={state.room.remainingMoves}
                />
                <Gamepad
                    directions={directions}
                    canPrimaryAction={
                        (cameraMode && isActive) ||
                        canRoll ||
                        canResolve ||
                        selectedDestination !== undefined
                    }
                    primaryActionLabel={
                        cameraMode
                            ? 'Zoom in'
                            : selectedDestination !== undefined
                              ? `Move to ${getNode(selectedDestination).label}`
                              : phase === 'revealingEncounter'
                                ? encounterReady
                                    ? 'Reveal result'
                                    : 'Spinning…'
                                : 'Roll dice'
                    }
                    onPrimaryAction={() => {
                        if (cameraMode) {
                            return dispatch(
                                gameCommand({
                                    type: 'camera.zoom',
                                    subjects: { roomId: state.room._id, playerId },
                                    data: { delta: -1 },
                                }),
                            )
                        }
                        if (selectedDestination !== undefined) {
                            return dispatch(
                                gameCommand({
                                    type: 'movement.step',
                                    subjects: { roomId: state.room._id, playerId },
                                    data: { destination: selectedDestination },
                                }),
                            )
                        }
                        if (canResolve && state.encounter) {
                            return dispatch(
                                gameCommand({
                                    type: 'encounter.resolve',
                                    subjects: {
                                        roomId: state.room._id,
                                        playerId,
                                        encounterId: state.encounter._id as Id<'encounters'>,
                                    },
                                    data: {},
                                }),
                            )
                        }
                        return dispatch(
                            gameCommand({
                                type: 'movement.roll',
                                subjects: { roomId: state.room._id, playerId },
                                data: {},
                            }),
                        )
                    }}
                    onInventory={() => setInventoryOpen(true)}
                    onBack={() => {
                        if (cameraMode) {
                            return dispatch(
                                gameCommand({
                                    type: 'camera.zoom',
                                    subjects: { roomId: state.room._id, playerId },
                                    data: { delta: 1 },
                                }),
                            )
                        }
                        if (selectedDestination !== undefined) {
                            return dispatch(
                                gameCommand({
                                    type: 'movement.cancel',
                                    subjects: { roomId: state.room._id, playerId },
                                    data: {},
                                }),
                            )
                        }
                        setInventoryOpen(false)
                    }}
                    canBack={inventoryOpen || cameraMode || selectedDestination !== undefined}
                    onSecondaryAction={!cameraMode ? beginDestinationMode : undefined}
                    secondaryActionLabel="Choose destination"
                    cameraMode={cameraMode}
                />
                <div className="utility-controls">
                    <button type="button" onClick={() => setInventoryOpen(true)}>
                        <span>▣</span> Inventory
                    </button>
                    <button
                        type="button"
                        className={cameraMode ? 'active' : ''}
                        disabled={!isActive || state.room.status !== 'playing'}
                        onClick={() =>
                            dispatch(
                                gameCommand({
                                    type: 'camera.toggle',
                                    subjects: { roomId: state.room._id, playerId },
                                    data: {},
                                }),
                            )
                        }
                    >
                        <span>◉</span> {cameraMode ? 'Follow hero' : 'Free camera'}
                    </button>
                </div>
                <ControllerOverlays
                    roomId={state.room._id}
                    playerId={playerId}
                    player={player}
                    active={isActive}
                    phase={phase}
                    shopKind={state.room.shopKind as ShopKind | undefined}
                    combat={state.combat}
                    inventoryOpen={inventoryOpen}
                    onCloseInventory={() => setInventoryOpen(false)}
                />
                {canResolve && (
                    <div className="waiting-card encounter-prompt">
                        <span className="pulse" /> Watch the wheel, then press A
                    </div>
                )}
                {!isActive && (
                    <div className="waiting-card">
                        <span className="pulse" /> Watch the main screen
                    </div>
                )}
                {state.room.status === 'lobby' && (
                    <div className="waiting-card">
                        <span className="pulse" /> Waiting for the host to start
                    </div>
                )}
                <p className="phone-message">{state.room.message}</p>
            </div>
        </main>
    )
}
