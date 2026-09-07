import { Float, Line, Text } from '@react-three/drei'
import { availableSteps, BOARD, getNode, WORLD } from '../../../shared/board.system'
import type { Player } from '../game.type'
import { SPACE_VISUALS } from './world.material'

function Ground() {
    return (
        <>
            <mesh receiveShadow position={[0, -0.42, 0]}>
                <cylinderGeometry args={[10.1, 10.7, 0.65, 20]} />
                <meshStandardMaterial color="#243a32" roughness={0.92} />
            </mesh>
            {Array.from({ length: 24 }).map((_, index) => {
                const angle = (index / 24) * Math.PI * 2
                const radius = 8.7 + (index % 3) * 0.4
                return (
                    <group
                        key={`tree-${angle}`}
                        position={[Math.cos(angle) * radius, 0, Math.sin(angle) * radius]}
                    >
                        <mesh castShadow position={[0, 0.42, 0]}>
                            <coneGeometry args={[0.32, 0.9, 6]} />
                            <meshStandardMaterial color={index % 2 ? '#4a7c59' : '#376a4c'} />
                        </mesh>
                        <mesh castShadow position={[0, -0.02, 0]}>
                            <cylinderGeometry args={[0.08, 0.1, 0.45, 6]} />
                            <meshStandardMaterial color="#684f3c" />
                        </mesh>
                    </group>
                )
            })}
        </>
    )
}

function Roads() {
    return WORLD.roads.map((road) => {
        const from = getNode(road.from)
        const to = getNode(road.to)
        const midpoint: [number, number, number] = [(from.x + to.x) / 2, 0.08, (from.z + to.z) / 2]
        const angle = Math.atan2(to.x - from.x, to.z - from.z)
        return (
            <group key={road.id}>
                <Line
                    points={[
                        [from.x, -0.02, from.z],
                        [to.x, -0.02, to.z],
                    ]}
                    color={road.bidirectional ? '#d5bd84' : '#f2c14e'}
                    lineWidth={10}
                />
                {!road.bidirectional && (
                    <mesh position={midpoint} rotation={[Math.PI / 2, angle, 0]}>
                        <coneGeometry args={[0.22, 0.52, 3]} />
                        <meshStandardMaterial color="#fff2b2" emissive="#db8b16" />
                    </mesh>
                )}
            </group>
        )
    })
}

function Space({
    node,
    reachable,
    selected,
}: {
    node: (typeof BOARD)[number]
    reachable: boolean
    selected: boolean
}) {
    const visual = SPACE_VISUALS[node.visualId]
    return (
        <group position={[node.x, -0.01, node.z]}>
            <mesh castShadow receiveShadow scale={selected ? 1.32 : reachable ? 1.16 : 1}>
                <cylinderGeometry args={[0.58, 0.61, 0.16, 32]} />
                <meshStandardMaterial
                    color={visual.color}
                    emissive={selected ? '#ffffff' : reachable ? '#f7cf67' : '#000000'}
                    emissiveIntensity={selected ? 1.2 : reachable ? 0.85 : 0}
                    roughness={0.55}
                />
            </mesh>
            <mesh position={[0, 0.085, 0]} rotation={[Math.PI / 2, 0, 0]}>
                <torusGeometry args={[0.49, 0.035, 8, 32]} />
                <meshStandardMaterial color="#f5e7bd" roughness={0.7} />
            </mesh>
            <Text
                position={[0, 0.095, 0]}
                rotation={[-Math.PI / 2, 0, 0]}
                fontSize={0.27}
                color="#171d25"
            >
                {visual.icon}
            </Text>
        </group>
    )
}

function Pawn({ player, offset }: { player: Player; offset: number }) {
    const node = getNode(player.position)
    return (
        <Float speed={2} rotationIntensity={0.08} floatIntensity={0.12}>
            <group position={[node.x + offset * 0.3, 0.55, node.z]}>
                <mesh castShadow>
                    <capsuleGeometry args={[0.2, 0.38, 6, 10]} />
                    <meshStandardMaterial color={player.color} roughness={0.38} />
                </mesh>
                <mesh castShadow position={[0, 0.45, 0]}>
                    <sphereGeometry args={[0.22, 16, 16]} />
                    <meshStandardMaterial color="#ffe0be" />
                </mesh>
                <mesh castShadow position={[0, 0.64, 0]} rotation={[0, 0, -0.08]}>
                    <coneGeometry args={[0.28, 0.35, 6]} />
                    <meshStandardMaterial color={player.color} />
                </mesh>
                <Text position={[0, 0.98, 0]} fontSize={0.2} color="white">
                    {player.name}
                </Text>
            </group>
        </Float>
    )
}

type BoardWorldProps = {
    players: Player[]
    activePlayer?: Player
    remainingMoves: number
    selectedDestination?: number
}

export function BoardWorld({
    players,
    activePlayer,
    remainingMoves,
    selectedDestination,
}: BoardWorldProps) {
    const reachable = new Set(
        activePlayer && remainingMoves > 0
            ? availableSteps(activePlayer.position, activePlayer.previousPosition)
            : [],
    )
    return (
        <>
            <Ground />
            <Roads />
            {BOARD.map((node) => (
                <Space
                    key={node.id}
                    node={node}
                    reachable={reachable.has(node.id)}
                    selected={node.id === selectedDestination}
                />
            ))}
            {players.map((player, index) => (
                <Pawn key={player._id} player={player} offset={index - (players.length - 1) / 2} />
            ))}
        </>
    )
}
