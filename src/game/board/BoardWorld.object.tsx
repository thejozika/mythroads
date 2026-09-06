import { Float, Line, Text } from '@react-three/drei'
import { BOARD, getNode, SPACE_COLORS } from '../../../shared/board.system'
import type { Player } from '../game.type'

function Ground() {
    return (
        <>
            <mesh receiveShadow position={[0, -0.42, 0]}>
                <cylinderGeometry args={[7.4, 8, 0.65, 12]} />
                <meshStandardMaterial color="#243a32" roughness={0.92} />
            </mesh>
            {Array.from({ length: 18 }).map((_, index) => {
                const angle = (index / 18) * Math.PI * 2
                const radius = 5.7 + (index % 3) * 0.45
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

function Space({ node }: { node: (typeof BOARD)[number] }) {
    return (
        <group position={[node.x, -0.01, node.z]}>
            <mesh castShadow receiveShadow>
                <cylinderGeometry args={[0.58, 0.61, 0.16, 32]} />
                <meshStandardMaterial color={SPACE_COLORS[node.kind]} roughness={0.55} />
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
                {node.kind === 'combat' ? '⚔' : node.kind === 'event' ? '?' : '★'}
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

export function BoardWorld({ players }: { players: Player[] }) {
    return (
        <>
            <Ground />
            <Roads />
            {BOARD.map((node) => (
                <Space key={node.id} node={node} />
            ))}
            {players.map((player, index) => (
                <Pawn key={player._id} player={player} offset={index - (players.length - 1) / 2} />
            ))}
        </>
    )
}
