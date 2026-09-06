import { OrbitControls } from '@react-three/drei'
import { Canvas } from '@react-three/fiber'
import type { Player } from '../game.type'
import { BoardWorld } from './BoardWorld.object'

export function BoardScene({ players }: { players: Player[] }) {
    return (
        <Canvas shadows camera={{ position: [0, 9, 8.5], fov: 43 }}>
            <color attach="background" args={['#8cc4bf']} />
            <fog attach="fog" args={['#8cc4bf', 13, 23]} />
            <ambientLight intensity={1.4} />
            <directionalLight castShadow position={[-4, 9, 4]} intensity={2.5} />
            <BoardWorld players={players} />
            <OrbitControls enablePan={false} minDistance={8} maxDistance={15} target={[0, 0, 0]} />
        </Canvas>
    )
}
