import { Float, Line, Text } from '@react-three/drei'
import { availableSteps, BOARD, getNode } from '../../../shared/board.system'
import type { Player } from '../game.type'
import { SPACE_VISUALS } from './world.material'

function Ground() {
    return (
        <>
            <mesh receiveShadow position={[0, -0.42, 0]}>
                <cylinderGeometry args={[9.1, 9.7, 0.65, 16]} />
                <meshStandardMaterial color="#243a32" roughness={0.92} />
            </mesh>
            {Array.from({ length: 24 }).map((_, index) => {
                const angle = (index / 24) * Math.PI * 2
                const radius = 7.7 + (index % 3) * 0.4
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
    const seen = new Set<string>()
    return BOARD.flatMap((node) =>
        node.neighbors.map((neighborId) => {
            const key = [node.id, neighborId].sort((a, b) => a - b).join('-')
            if (seen.has(key)) return null
            seen.add(key)
            const neighbor = getNode(neighborId)
            return (
                <Line
                    key={key}
                    points={[
                        [node.x, -0.02, node.z],
                        [neighbor.x, -0.02, neighbor.z],
                    ]}
                    color="#d5bd84"
                    lineWidth={12}
                />
            )
        }),
    )
}

function Space({ node, reachable }: { node: (typeof BOARD)[number]; reachable: boolean }) {
    const visual = SPACE_VISUALS[node.visualId]
    return (
        <group position={[node.x, -0.01, node.z]}>
            <mesh castShadow receiveShadow scale={reachable ? 1.16 : 1}>
                <cylinderGeometry args={[0.58, 0.61, 0.16, 32]} />
                <meshStandardMaterial
                    color={visual.color}
                    emissive={reachable ? '#f7cf67' : '#000000'}
                    emissiveIntensity={reachable ? 0.85 : 0}
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

type BoardWorldProps = { players: Player[]; activePlayer?: Player; remainingMoves: number }

export function BoardWorld({ players, activePlayer, remainingMoves }: BoardWorldProps) {
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
                <Space key={node.id} node={node} reachable={reachable.has(node.id)} />
            ))}
            {players.map((player, index) => (
                <Pawn key={player._id} player={player} offset={index - (players.length - 1) / 2} />
            ))}
        </>
    )
}
