import { useFrame } from '@react-three/fiber'
import { useEffect, useRef, useState } from 'react'
import type { Group } from 'three'
import { getNode } from '../../../shared/board.system'
import { BoardText as Text } from './labels/BoardText.object'

export function DiceThrow({ results, originId }: { results?: number[]; originId: number }) {
    const group = useRef<Group>(null)
    const startedAt = useRef(0)
    const [visible, setVisible] = useState(false)
    const signature = results?.join('-') ?? ''
    useEffect(() => {
        if (!signature) return
        startedAt.current = performance.now()
        setVisible(true)
    }, [signature])
    useFrame((_, delta) => {
        if (!group.current || !visible) return
        group.current.rotation.x += delta * 7
        group.current.rotation.y += delta * 9
        const age = (performance.now() - startedAt.current) / 1000
        group.current.position.y = 1.25 + Math.sin(Math.min(1, age) * Math.PI) * 0.85
        if (age > 1.45) setVisible(false)
    })
    if (!visible || !results?.length) return null
    const node = getNode(originId)
    return (
        <group ref={group} position={[node.x + 0.55, 1.25, node.z]}>
            {results
                .map((result, index) => ({
                    result,
                    offset: (index - (results.length - 1) / 2) * 0.48,
                }))
                .map(({ result, offset }) => (
                    <group position={[offset, 0, 0]} key={`${result}-${offset}`}>
                        <mesh castShadow>
                            <boxGeometry args={[0.38, 0.38, 0.38]} />
                            <meshStandardMaterial color="#fff8db" roughness={0.42} />
                        </mesh>
                        <Text position={[0, 0, 0.195]} fontSize={0.2} color="#263631">
                            {result}
                        </Text>
                    </group>
                ))}
        </group>
    )
}
