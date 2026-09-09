import { Float, Text } from '@react-three/drei'
import { ATTACK_LABELS, isMagicTechnique, type CombatAttack } from '../../../shared/combat.system'
import { MAGIC_TECHNIQUES, type Element } from '../../../shared/magic.system'
import type { Combat, PublicPlayer } from '../game.type'

const ELEMENT_COLOR: Record<Element, string> = {
    fire: '#ff6b4a',
    water: '#55a9ff',
    wind: '#75dec0',
    earth: '#d49a58',
}

function ArenaFloor({ element }: { element: Element }) {
    return (
        <group>
            <mesh receiveShadow position={[0, -0.28, 0]}>
                <cylinderGeometry args={[4.8, 5.2, 0.55, 48]} />
                <meshStandardMaterial color="#233932" roughness={0.82} />
            </mesh>
            <mesh position={[0, 0.015, 0]} rotation={[Math.PI / 2, 0, 0]}>
                <torusGeometry args={[3.65, 0.08, 12, 64]} />
                <meshStandardMaterial
                    color={ELEMENT_COLOR[element]}
                    emissive={ELEMENT_COLOR[element]}
                    emissiveIntensity={0.65}
                />
            </mesh>
        </group>
    )
}

function Hero({ player }: { player: PublicPlayer }) {
    return (
        <group position={[-2.1, 0.55, 0]} rotation={[0, 0.45, 0]}>
            <mesh castShadow>
                <capsuleGeometry args={[0.42, 0.9, 8, 16]} />
                <meshStandardMaterial color={player.color} roughness={0.35} />
            </mesh>
            <mesh castShadow position={[0, 0.88, 0]}>
                <sphereGeometry args={[0.43, 24, 24]} />
                <meshStandardMaterial color="#ffe0be" />
            </mesh>
            <mesh castShadow position={[0, 1.28, 0]} rotation={[0, 0, -0.08]}>
                <coneGeometry args={[0.53, 0.65, 7]} />
                <meshStandardMaterial color={player.color} />
            </mesh>
            <mesh castShadow position={[0.55, 0.35, 0]} rotation={[0, 0, -0.4]}>
                <boxGeometry args={[0.1, 1.3, 0.13]} />
                <meshStandardMaterial color="#e5d5a6" metalness={0.55} />
            </mesh>
        </group>
    )
}

function Enemy({ combat }: { combat: Combat }) {
    const color = ELEMENT_COLOR[combat.enemyElement]
    return (
        <Float speed={1.8} floatIntensity={0.18} rotationIntensity={0.06}>
            <group position={[2.1, 0.72, 0]} rotation={[0, -0.45, 0]}>
                <mesh castShadow>
                    <dodecahedronGeometry args={[0.92, 1]} />
                    <meshStandardMaterial color={color} roughness={0.48} />
                </mesh>
                <mesh castShadow position={[-0.47, 0.72, 0]} rotation={[0, 0, 0.45]}>
                    <coneGeometry args={[0.22, 0.75, 6]} />
                    <meshStandardMaterial color="#fff0c2" />
                </mesh>
                <mesh castShadow position={[0.47, 0.72, 0]} rotation={[0, 0, -0.45]}>
                    <coneGeometry args={[0.22, 0.75, 6]} />
                    <meshStandardMaterial color="#fff0c2" />
                </mesh>
            </group>
        </Float>
    )
}

function LastAction({ combat }: { combat: Combat }) {
    if (!combat.lastAttack) return null
    const attack = combat.lastAttack as CombatAttack
    const magical = isMagicTechnique(attack)
    const color = magical ? ELEMENT_COLOR[MAGIC_TECHNIQUES[attack].element] : '#f5cf68'
    return (
        <Float speed={3} floatIntensity={0.3}>
            <group position={[0, 1.05, 0]}>
                <mesh rotation={[Math.PI / 2, 0, 0]}>
                    <torusGeometry args={[0.54, 0.1, 12, 40]} />
                    <meshStandardMaterial color={color} emissive={color} emissiveIntensity={1.2} />
                </mesh>
                <Text position={[0, 0.05, 0.12]} fontSize={0.22} color="#fff8dd">
                    {magical
                        ? ATTACK_LABELS[attack]
                        : combat.lastDamage
                          ? `-${combat.lastDamage}`
                          : 'MISS'}
                </Text>
            </group>
        </Float>
    )
}

export function CombatStage({ combat, player }: { combat: Combat; player: PublicPlayer }) {
    return (
        <>
            <ArenaFloor element={combat.enemyElement} />
            <Hero player={player} />
            <Enemy combat={combat} />
            <LastAction combat={combat} />
        </>
    )
}
