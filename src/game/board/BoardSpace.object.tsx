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

function DestinationArrow({ selected }: { selected: boolean }) {
    return (
        <Float speed={3} floatIntensity={0.22} rotationIntensity={0}>
            <Billboard position={[0, selected ? 1.42 : 1.18, 0]}>
                <Text fontSize={selected ? 0.48 : 0.36} color={selected ? '#fff7b2' : '#ffffff'}>
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
            <Text
                position={[0, 0.03, 0]}
                rotation={[-Math.PI / 2, 0, 0]}
                fontSize={0.25}
                color="#17221e"
            >
                {visual.icon}
            </Text>
            {reachable && <DestinationArrow selected={selected} />}
            {selected && <Crosshair />}
        </group>
    )
}
