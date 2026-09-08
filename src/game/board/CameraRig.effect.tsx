import { useFrame, useThree } from '@react-three/fiber'
import { useMemo } from 'react'
import { PerspectiveCamera, Vector3 } from 'three'
import { getNode } from '../../../shared/board.system'
import type { Player, RoomCamera } from '../game.type'

type CameraRigProps = {
    activePlayer?: Player
    cameraState: RoomCamera | null
    combatActive?: boolean
    targeting?: boolean
}

export function CameraRig({ activePlayer, cameraState, combatActive, targeting }: CameraRigProps) {
    const camera = useThree((state) => state.camera)
    const desired = useMemo(() => new Vector3(), [])
    const fixedRotation = useMemo(() => {
        const anchor = new PerspectiveCamera()
        anchor.position.set(0, 0.82, 0.72)
        anchor.lookAt(0, 0, 0)
        return anchor.quaternion.clone()
    }, [])

    useFrame((_, delta) => {
        const activeNode = activePlayer ? getNode(activePlayer.position) : undefined
        const free = !combatActive && cameraState?.mode === 'free'
        const targetX = free ? cameraState.targetX : targeting ? 0 : (activeNode?.x ?? 0)
        const targetZ = free ? cameraState.targetZ : targeting ? 0 : (activeNode?.z ?? 0)
        const distance = free
            ? cameraState.distance
            : combatActive
              ? 8.3
              : activePlayer && !targeting
                ? 9.2
                : 13.4
        if (combatActive) {
            desired.set(0, distance * 0.72, distance * 0.86)
        } else {
            desired.set(targetX, distance * 0.82, targetZ + distance * 0.72)
        }
        const smoothing = 1 - Math.exp(-delta * 4.5)
        camera.position.lerp(desired, smoothing)
        camera.quaternion.slerp(fixedRotation, smoothing)
    })

    return null
}
