import { Billboard, Float, Text } from '@react-three/drei'
import { useFrame } from '@react-three/fiber'
import { useMemo, useRef } from 'react'
import type { Group } from 'three'
import { Vector3 } from 'three'
import { getNode } from '../../../shared/board.system'
import type { PublicPlayer } from '../game.type'

export function BoardPawn({
    player,
    offset,
    movementPoints,
}: {
    player: PublicPlayer
    offset: number
    movementPoints?: number
}) {
    const node = getNode(player.position)
    const group = useRef<Group>(null)
    const target = useMemo(() => new Vector3(), [])
    target.set(node.x + offset * 0.25, 0.45, node.z)
    useFrame((_, delta) => {
        if (!group.current) return
        const smoothing = 1 - Math.exp(-delta * 7)
        group.current.position.lerp(target, smoothing)
    })
    return (
        <Float speed={2} rotationIntensity={0.08} floatIntensity={0.12}>
            <group ref={group} position={[node.x + offset * 0.25, 0.45, node.z]}>
                <mesh castShadow>
                    <capsuleGeometry args={[0.18, 0.32, 6, 10]} />
                    <meshStandardMaterial color={player.color} roughness={0.38} />
                </mesh>
                <mesh castShadow position={[0, 0.39, 0]}>
                    <sphereGeometry args={[0.19, 16, 16]} />
                    <meshStandardMaterial color="#ffe0be" />
                </mesh>
                <mesh castShadow position={[0, 0.56, 0]} rotation={[0, 0, -0.08]}>
                    <coneGeometry args={[0.24, 0.3, 6]} />
                    <meshStandardMaterial color={player.color} />
                </mesh>
                <Text position={[0, 0.86, 0]} fontSize={0.18} color="white">
                    {player.name}
                </Text>
                {movementPoints !== undefined && (
                    <Billboard position={[0, 1.36, 0]}>
                        <mesh>
                            <circleGeometry args={[0.23, 24]} />
                            <meshBasicMaterial color="#203b34" depthTest={false} />
                        </mesh>
                        <Text
                            position={[0, 0, 0.01]}
                            fontSize={0.25}
                            color="#fff2a8"
                            anchorX="center"
                            anchorY="middle"
                            outlineWidth={0.012}
                            outlineColor="#203b34"
                        >
                            {movementPoints}
                        </Text>
                    </Billboard>
                )}
            </group>
        </Float>
    )
}
