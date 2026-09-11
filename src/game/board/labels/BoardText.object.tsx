import { Text } from '@react-three/drei'
import { type ComponentProps, Suspense } from 'react'
import { BOARD_FONT_URL } from './board-font.asset'

/** Font loading must not suspend terrain, pawns, or the camera's frame updates. */
export function BoardText(props: ComponentProps<typeof Text>) {
    return (
        <Suspense fallback={null}>
            <Text font={BOARD_FONT_URL} {...props} />
        </Suspense>
    )
}
