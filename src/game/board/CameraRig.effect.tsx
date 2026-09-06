import { useFrame, useThree } from '@react-three/fiber'
import { useMemo } from 'react'
import { Vector3 } from 'three'
import { getNode } from '../../../shared/board.system'
import type { Player, RoomCamera } from '../game.type'

type CameraRigProps = { activePlayer?: Player; cameraState: RoomCamera | null }

export function CameraRig({ activePlayer, cameraState }: CameraRigProps) {
    const camera = useThree((state) => state.camera)
    const target = useMemo(() => new Vector3(), [])
    const desired = useMemo(() => new Vector3(), [])

    useFrame((_, delta) => {
        const activeNode = getNode(activePlayer?.position ?? 0)
        const free = cameraState?.mode === 'free'
        const targetX = free ? cameraState.targetX : activeNode.x
        const targetZ = free ? cameraState.targetZ : activeNode.z
        const distance = free ? cameraState.distance : 7.2
        target.set(targetX, 0.25, targetZ)
        desired.set(targetX, distance * 0.82, targetZ + distance * 0.72)
        const smoothing = 1 - Math.exp(-delta * 4.5)
        camera.position.lerp(desired, smoothing)
        camera.lookAt(target)
    })

    return null
}
