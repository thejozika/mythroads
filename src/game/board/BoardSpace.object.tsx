import { Billboard, Float } from '@react-three/drei'
import type { BOARD } from '../../../shared/board.system'
import { BoardText as Text } from './labels/BoardText.object'
import { SPACE_VISUALS } from './world.material'

type BoardNode = (typeof BOARD)[number]

function FieldGeometry({ node }: { node: BoardNode }) {
    const shop = ['armoury', 'jeweller', 'weapons', 'items', 'magic'].includes(node.kind)
    return <boxGeometry args={[shop ? 0.82 : 0.74, 0.035, shop ? 0.66 : 0.62]} />
}

function TeleportGate() {
    return (
        <Float speed={2.2} floatIntensity={0.08} rotationIntensity={0.18}>
            <group position={[0, 0.3, 0]} rotation={[Math.PI / 2, 0, 0]}>
                <mesh>
                    <torusGeometry args={[0.28, 0.055, 8, 24]} />
                    <meshStandardMaterial
                        color="#8ff8ed"
                        emissive="#2aa9b4"
                        emissiveIntensity={1.4}
                    />
                </mesh>
                <mesh>
                    <circleGeometry args={[0.22, 24]} />
                    <meshBasicMaterial color="#347ea1" transparent opacity={0.72} />
                </mesh>
            </group>
        </Float>
    )
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
            <Text
                position={[0, 0.03, 0]}
                rotation={[-Math.PI / 2, 0, 0]}
                fontSize={0.25}
                color="#17221e"
            >
                {visual.icon}
            </Text>
            {node.landmark?.visualId === 'landmark.castle' && (
                <group position={[node.landmark.offsetX, 0, node.landmark.offsetZ]}>
                    <Castle />
                </group>
            )}
            {node.kind === 'teleport' && <TeleportGate />}
            {reachable && <DestinationArrow selected={selected} />}
            {selected && <Crosshair />}
        </group>
    )
}
