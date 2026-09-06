import { Canvas } from '@react-three/fiber'
import type { Player, RoomCamera } from '../game.type'
import { BoardWorld } from './BoardWorld.object'
import { CameraRig } from './CameraRig.effect'

type BoardSceneProps = {
    players: Player[]
    activePlayer?: Player
    remainingMoves: number
    cameraState: RoomCamera | null
}

export function BoardScene({
    players,
    activePlayer,
    remainingMoves,
    cameraState,
}: BoardSceneProps) {
    return (
        <Canvas shadows camera={{ position: [0, 12, 11.5], fov: 44 }}>
            <color attach="background" args={['#8cc4bf']} />
            <fog attach="fog" args={['#8cc4bf', 13, 23]} />
            <ambientLight intensity={1.4} />
            <directionalLight castShadow position={[-4, 9, 4]} intensity={2.5} />
            <CameraRig activePlayer={activePlayer} cameraState={cameraState} />
            <BoardWorld
                players={players}
                activePlayer={activePlayer}
                remainingMoves={remainingMoves}
            />
        </Canvas>
    )
}
