import { BufferGeometry, Float32BufferAttribute } from 'three'
import { getNode, WORLD } from '../../../shared/board.system'
import type { WorldRoad } from '../../../shared/world.type'

export type PathPoint = { x: number; z: number }

export function roadPoints(road: WorldRoad, reverse = false): PathPoint[] {
    const points = [getNode(road.from), ...(road.via ?? []), getNode(road.to)]
    return reverse ? points.reverse() : points
}

export function roadBetween(from: number, to: number) {
    const road = WORLD.roads.find(
        (candidate) =>
            (candidate.from === from && candidate.to === to) ||
            (candidate.bidirectional && candidate.from === to && candidate.to === from),
    )
    if (!road) return null
    return roadPoints(road, road.to === from)
}

export function offsetPath(points: PathPoint[], distance: number) {
    return points.map((point, index) => {
        const before = points[Math.max(0, index - 1)]
        const after = points[Math.min(points.length - 1, index + 1)]
        const dx = after.x - before.x
        const dz = after.z - before.z
        const length = Math.hypot(dx, dz) || 1
        return { x: point.x - (dz / length) * distance, z: point.z + (dx / length) * distance }
    })
}

export function ribbonGeometry(points: PathPoint[], width: number, y: number) {
    const vertices: number[] = []
    for (let index = 0; index < points.length - 1; index += 1) {
        const from = points[index]
        const to = points[index + 1]
        const dx = to.x - from.x
        const dz = to.z - from.z
        const length = Math.hypot(dx, dz) || 1
        const nx = (-dz / length) * width * 0.5
        const nz = (dx / length) * width * 0.5
        vertices.push(
            from.x + nx,
            y,
            from.z + nz,
            to.x + nx,
            y,
            to.z + nz,
            to.x - nx,
            y,
            to.z - nz,
            from.x + nx,
            y,
            from.z + nz,
            to.x - nx,
            y,
            to.z - nz,
            from.x - nx,
            y,
            from.z - nz,
        )
    }
    const geometry = new BufferGeometry()
    geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3))
    geometry.computeVertexNormals()
    return geometry
}

export function arrowGeometry(points: PathPoint[], y: number) {
    const vertices: number[] = []
    for (let index = 0; index < points.length - 1; index += 1) {
        const from = points[index]
        const to = points[index + 1]
        const dx = to.x - from.x
        const dz = to.z - from.z
        const length = Math.hypot(dx, dz)
        const ux = dx / length
        const uz = dz / length
        const nx = -uz
        const nz = ux
        const count = Math.max(1, Math.floor(length / 0.65))
        for (let arrow = 1; arrow <= count; arrow += 1) {
            const t = arrow / (count + 1)
            const x = from.x + dx * t
            const z = from.z + dz * t
            vertices.push(
                x + ux * 0.17,
                y,
                z + uz * 0.17,
                x - ux * 0.12 + nx * 0.11,
                y,
                z - uz * 0.12 + nz * 0.11,
                x - ux * 0.12 - nx * 0.11,
                y,
                z - uz * 0.12 - nz * 0.11,
            )
        }
    }
    const geometry = new BufferGeometry()
    geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3))
    geometry.computeVertexNormals()
    return geometry
}
