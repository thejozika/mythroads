import { OrbitControls } from '@react-three/drei'
import { Canvas } from '@react-three/fiber'
import type { Player } from '../game.type'
import { BoardWorld } from './BoardWorld.object'

type BoardSceneProps = {
    players: Player[]
    activePlayer?: Player
    remainingMoves: number
}

export function BoardScene({ players, activePlayer, remainingMoves }: BoardSceneProps) {
    return (
        <Canvas shadows camera={{ position: [0, 12, 11.5], fov: 44 }}>
            <color attach="background" args={['#8cc4bf']} />
            <fog attach="fog" args={['#8cc4bf', 13, 23]} />
            <ambientLight intensity={1.4} />
            <directionalLight castShadow position={[-4, 9, 4]} intensity={2.5} />
            <BoardWorld
                players={players}
                activePlayer={activePlayer}
                remainingMoves={remainingMoves}
            />
            <OrbitControls
                enablePan={false}
                enableRotate={false}
                minDistance={11}
                maxDistance={18}
                target={[0, 0, 0]}
            />
        </Canvas>
    )
}
