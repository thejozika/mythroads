import { useMemo } from 'react'
import { Shape } from 'three'
import { WORLD } from '../../../shared/board.system'
import type { WorldTerrainFeature } from '../../../shared/world.type'
import { ribbonGeometry } from './board-path.geometry'

const ISLAND_EDGE = [
    [-6.4, -2.5],
    [-3.2, -2.8],
    [0.1, -2.65],
    [3.5, -2.8],
    [5.8, -2.25],
    [6.1, 0.8],
    [5.9, 3.6],
    [4.2, 5.3],
    [0.4, 5.65],
    [-3.1, 5.5],
    [-6.2, 4.55],
    [-6.6, 1.2],
] as const

function TerrainPatch({
    position,
    scale,
    color,
}: {
    position: [number, number, number]
    scale: [number, number]
    color: string
}) {
    return (
        <mesh position={position} rotation={[-Math.PI / 2, 0, 0]} scale={[scale[0], scale[1], 1]}>
            <circleGeometry args={[1, 16]} />
            <meshStandardMaterial color={color} roughness={1} />
        </mesh>
    )
}

function Scenery() {
    const trees = [
        [-5, 1.5],
        [-4.2, 0.5],
        [-4.8, -1],
        [-2.2, 2.7],
        [-1, 3.2],
        [1.4, 3.2],
        [2.7, 3.1],
        [4.7, 1.4],
        [4.6, -0.4],
        [-1, -2],
    ] as const
    return trees.map(([x, z], index) => (
        <group position={[x, 0, z]} key={`grove-${x}-${z}`}>
            <mesh castShadow position={[0, 0.2, 0]}>
                <coneGeometry args={[0.24 + (index % 2) * 0.06, 0.7, 7]} />
                <meshStandardMaterial color={index % 2 ? '#356a50' : '#477c55'} roughness={0.9} />
            </mesh>
            <mesh castShadow position={[0, -0.12, 0]}>
                <cylinderGeometry args={[0.055, 0.07, 0.28, 6]} />
                <meshStandardMaterial color="#654831" />
            </mesh>
        </group>
    ))
}

function Hill({ feature }: { feature: Extract<WorldTerrainFeature, { kind: 'hill' }> }) {
    return (
        <group position={[feature.x, -0.03, feature.z]}>
            <mesh receiveShadow scale={[feature.radius, feature.height, feature.radius]}>
                <sphereGeometry args={[1, 14, 7, 0, Math.PI * 2, 0, Math.PI / 2]} />
                <meshStandardMaterial color="#6e8957" roughness={1} />
            </mesh>
            <mesh castShadow position={[0, feature.height * 0.72, 0]}>
                <coneGeometry args={[0.32, 0.9, 7]} />
                <meshStandardMaterial color="#315f47" roughness={0.9} />
            </mesh>
        </group>
    )
}

function Water() {
    const lake = WORLD.terrain.find(
        (feature): feature is Extract<WorldTerrainFeature, { kind: 'lake' }> =>
            feature.kind === 'lake',
    )
    const river = WORLD.terrain.find(
        (feature): feature is Extract<WorldTerrainFeature, { kind: 'river' }> =>
            feature.kind === 'river',
    )
    return (
        <>
            {river && (
                <mesh geometry={ribbonGeometry(river.points, river.width, -0.065)}>
                    <meshStandardMaterial color="#5598a3" roughness={0.35} />
                </mesh>
            )}
            {lake && (
                <mesh
                    position={[lake.x, -0.06, lake.z]}
                    rotation={[-Math.PI / 2, 0, 0]}
                    scale={[lake.radiusX, lake.radiusZ, 1]}
                >
                    <circleGeometry args={[1, 24]} />
                    <meshStandardMaterial color="#5598a3" roughness={0.35} />
                </mesh>
            )}
        </>
    )
}

export function BoardGround() {
    const island = useMemo(() => {
        const shape = new Shape()
        ISLAND_EDGE.forEach(([x, z], index) => {
            if (index === 0) shape.moveTo(x, -z)
            else shape.lineTo(x, -z)
        })
        shape.closePath()
        return shape
    }, [])
    return (
        <>
            <mesh receiveShadow position={[0, -0.11, 0]} rotation={[-Math.PI / 2, 0, 0]}>
                <shapeGeometry args={[island]} />
                <meshStandardMaterial color="#3d664c" roughness={1} />
            </mesh>
            <TerrainPatch position={[-4.5, -0.095, 1]} scale={[1.4, 2]} color="#527b50" />
            <TerrainPatch position={[2.8, -0.09, 3.2]} scale={[2.2, 1.45]} color="#66845a" />
            <TerrainPatch position={[3.9, -0.085, -0.8]} scale={[1.8, 1.2]} color="#496f52" />
            <TerrainPatch position={[-1.4, -0.08, -1.4]} scale={[1.6, 0.8]} color="#57764e" />
            <Water />
            {WORLD.terrain
                .filter(
                    (feature): feature is Extract<WorldTerrainFeature, { kind: 'hill' }> =>
                        feature.kind === 'hill',
                )
                .map((feature) => (
                    <Hill feature={feature} key={feature.id} />
                ))}
            <Scenery />
        </>
    )
}
