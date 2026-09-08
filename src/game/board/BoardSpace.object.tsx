import { Billboard, Float, Text } from '@react-three/drei'
import type { BOARD } from '../../../shared/board.system'
import { SPACE_VISUALS } from './world.material'

type BoardNode = (typeof BOARD)[number]

function FieldGeometry({ node }: { node: BoardNode }) {
    const shop = ['armoury', 'jeweller', 'weapons', 'items', 'magic'].includes(node.kind)
    if (shop) return <boxGeometry args={[0.78, 0.035, 0.62]} />
    if (node.kind === 'event') return <cylinderGeometry args={[0.49, 0.49, 0.035, 4]} />
    if (node.kind === 'combat') return <cylinderGeometry args={[0.5, 0.5, 0.035, 6]} />
    return <cylinderGeometry args={[0.53, 0.53, 0.035, 8]} />
}

function Castle() {
    return (
        <group position={[0, 0.17, 0]}>
            <mesh castShadow position={[0, 0.22, 0]}>
                <boxGeometry args={[0.42, 0.44, 0.34]} />
                <meshStandardMaterial color="#f0dfac" roughness={0.8} />
            </mesh>
            {[-0.27, 0.27].map((x) => (
                <group position={[x, 0.2, 0]} key={x}>
                    <mesh castShadow>
                        <cylinderGeometry args={[0.14, 0.17, 0.48, 8]} />
                        <meshStandardMaterial color="#e6d29b" roughness={0.82} />
                    </mesh>
                    <mesh castShadow position={[0, 0.32, 0]}>
                        <coneGeometry args={[0.19, 0.25, 8]} />
                        <meshStandardMaterial color="#c65f55" roughness={0.72} />
                    </mesh>
                </group>
            ))}
            <mesh position={[0, 0.11, 0.176]}>
                <planeGeometry args={[0.13, 0.2]} />
                <meshBasicMaterial color="#513f34" />
            </mesh>
        </group>
    )
}

function DestinationArrow({ selected }: { selected: boolean }) {
    return (
        <Float speed={3} floatIntensity={0.22} rotationIntensity={0}>
            <Billboard position={[0, selected ? 0.92 : 0.72, 0]}>
                <Text fontSize={selected ? 0.42 : 0.32} color={selected ? '#fff7b2' : '#ffffff'}>
                    ▼
                </Text>
            </Billboard>
        </Float>
    )
}

function Crosshair() {
    return (
        <group position={[0, 0.055, 0]}>
            <mesh rotation={[-Math.PI / 2, 0, 0]}>
                <ringGeometry args={[0.52, 0.58, 32]} />
                <meshBasicMaterial color="#fff2a8" />
            </mesh>
            {[0, Math.PI / 2].map((rotation) => (
                <mesh
                    position={[0, 0.004, 0]}
                    rotation={[-Math.PI / 2, 0, rotation]}
                    key={rotation}
                >
                    <planeGeometry args={[1.35, 0.035]} />
                    <meshBasicMaterial color="#fff2a8" />
                </mesh>
            ))}
        </group>
    )
}

export function BoardSpace({
    node,
    reachable,
    selected,
}: {
    node: BoardNode
    reachable: boolean
    selected: boolean
}) {
    const visual = SPACE_VISUALS[node.visualId]
    return (
        <group position={[node.x, -0.015, node.z]}>
            <mesh receiveShadow>
                <FieldGeometry node={node} />
                <meshStandardMaterial color={visual.color} roughness={0.82} />
            </mesh>
            {node.kind === 'castle' ? (
                <Castle />
            ) : (
                <Text
                    position={[0, 0.03, 0]}
                    rotation={[-Math.PI / 2, 0, 0]}
                    fontSize={0.25}
                    color="#17221e"
                >
                    {visual.icon}
                </Text>
            )}
            {reachable && <DestinationArrow selected={selected} />}
            {selected && <Crosshair />}
        </group>
    )
}
