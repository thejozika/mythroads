import { useCallback, useEffect, useRef, useState } from 'react'

export function useHeldAction(action: (() => void) | undefined, repeat = false) {
    const [pressed, setPressed] = useState(false)
    const actionRef = useRef(action)
    const timerRef = useRef<number | null>(null)
    const pointerTriggeredRef = useRef(false)
    actionRef.current = action

    const release = useCallback(() => {
        setPressed(false)
        if (timerRef.current !== null) window.clearInterval(timerRef.current)
        timerRef.current = null
    }, [])

    useEffect(() => release, [release])

    const press = useCallback(
        (event: React.PointerEvent<HTMLButtonElement>) => {
            if (!actionRef.current) return
            event.preventDefault()
            event.currentTarget.setPointerCapture(event.pointerId)
            pointerTriggeredRef.current = true
            setPressed(true)
            navigator.vibrate?.(8)
            actionRef.current()
            if (repeat) {
                timerRef.current = window.setInterval(() => actionRef.current?.(), 180)
            }
        },
        [repeat],
    )

    const click = useCallback(() => {
        if (pointerTriggeredRef.current) {
            pointerTriggeredRef.current = false
            return
        }
        actionRef.current?.()
    }, [])

    return {
        pressed,
        pressProps: {
            onPointerDown: press,
            onPointerUp: release,
            onPointerCancel: release,
            onLostPointerCapture: release,
            onClick: click,
        },
    }
}
