import { Canvas } from '@react-three/fiber'
import { CombatStage } from '../combat/CombatStage.object'
import type { Combat, Player, RoomCamera } from '../game.type'
import { BoardWorld } from './BoardWorld.object'
import { CameraRig } from './CameraRig.effect'
import { DiceThrow } from './DiceThrow.object'

type BoardSceneProps = {
    players: Player[]
    activePlayer?: Player
    remainingMoves: number
    cameraState: RoomCamera | null
    selectedDestination?: number
    selectedPath?: number[]
    combat: Combat | null
    lastRoll?: number[]
}

export function BoardScene({
    players,
    activePlayer,
    remainingMoves,
    cameraState,
    selectedDestination,
    selectedPath,
    combat,
    lastRoll,
}: BoardSceneProps) {
    return (
        <Canvas shadows camera={{ position: [0, 12, 11.5], fov: 44 }}>
            <color attach="background" args={[combat ? '#14251f' : '#8cc4bf']} />
            <fog attach="fog" args={[combat ? '#14251f' : '#8cc4bf', 13, 23]} />
            <ambientLight intensity={1.4} />
            <directionalLight castShadow position={[-4, 9, 4]} intensity={2.5} />
            <CameraRig
                activePlayer={activePlayer}
                cameraState={cameraState}
                combatActive={Boolean(combat)}
                targeting={selectedDestination !== undefined}
            />
            {combat && activePlayer ? (
                <CombatStage combat={combat} player={activePlayer} />
            ) : (
                <BoardWorld
                    players={players}
                    activePlayer={activePlayer}
                    remainingMoves={remainingMoves}
                    selectedDestination={selectedDestination}
                    selectedPath={selectedPath}
                />
            )}
            {!combat && activePlayer && (
                <DiceThrow results={lastRoll} originId={activePlayer.position} />
            )}
        </Canvas>
    )
}
