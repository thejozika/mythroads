import { useMemo } from 'react'
import { WORLD } from '../../../shared/board.system'
import {
    arrowGeometry,
    offsetPath,
    ribbonGeometry,
    roadBetween,
    roadPoints,
} from './board-path.geometry'

function Road({ road }: { road: (typeof WORLD.roads)[number] }) {
    const points = useMemo(() => roadPoints(road), [road])
    const height = road.bridge ? 0.035 : -0.045
    const base = useMemo(
        () => ribbonGeometry(points, road.bridge ? 0.3 : road.bidirectional ? 0.42 : 0.34, height),
        [points, road.bidirectional, road.bridge, height],
    )
    const left = useMemo(
        () => ribbonGeometry(offsetPath(points, 0.09), 0.035, height + 0.006),
        [points, height],
    )
    const right = useMemo(
        () => ribbonGeometry(offsetPath(points, -0.09), 0.035, height + 0.006),
        [points, height],
    )
    const arrows = useMemo(() => arrowGeometry(points, height + 0.01), [points, height])
    return (
        <group>
            <mesh geometry={base} receiveShadow={road.bridge}>
                <meshStandardMaterial
                    color={road.bridge ? '#9b7957' : '#cbbd91'}
                    roughness={0.95}
                />
            </mesh>
            {!road.bidirectional && (
                <>
                    <mesh geometry={left}>
                        <meshBasicMaterial color="#fff0a8" />
                    </mesh>
                    <mesh geometry={right}>
                        <meshBasicMaterial color="#fff0a8" />
                    </mesh>
                    <mesh geometry={arrows}>
                        <meshBasicMaterial color="#8b5528" />
                    </mesh>
                </>
            )}
            {road.bridge && (
                <>
                    <mesh geometry={left}>
                        <meshBasicMaterial color="#ead8ae" />
                    </mesh>
                    <mesh geometry={right}>
                        <meshBasicMaterial color="#ead8ae" />
                    </mesh>
                </>
            )}
        </group>
    )
}

function SelectedRoute({ nodeIds }: { nodeIds: number[] }) {
    const segments = useMemo(
        () =>
            nodeIds.slice(1).flatMap((nodeId, index) => {
                const points = roadBetween(nodeIds[index], nodeId)
                return points
                    ? [
                          {
                              ribbon: ribbonGeometry(points, 0.16, 0.015),
                              arrows: arrowGeometry(points, 0.023),
                          },
                      ]
                    : []
            }),
        [nodeIds],
    )
    return segments.map((segment, index) => (
        <group key={`selected-road-${nodeIds[index]}-${nodeIds[index + 1]}`}>
            <mesh geometry={segment.ribbon}>
                <meshBasicMaterial color="#fff2a8" />
            </mesh>
            <mesh geometry={segment.arrows}>
                <meshBasicMaterial color="#725628" />
            </mesh>
        </group>
    ))
}

export function BoardRoads({ selectedRoute }: { selectedRoute?: number[] }) {
    return (
        <>
            {WORLD.roads.map((road) => (
                <Road road={road} key={road.id} />
            ))}
            {selectedRoute && <SelectedRoute nodeIds={selectedRoute} />}
        </>
    )
}
