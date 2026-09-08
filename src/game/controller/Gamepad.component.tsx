import type { CardinalDirection } from '../../../shared/controller-input.system'
import { useHeldAction } from './useHeldAction.hook'

type DirectionAction = { run: () => void; label: string; kind: string }
type DirectionActions = Partial<Record<CardinalDirection, DirectionAction>>

type GamepadProps = {
    directions: DirectionActions
    canPrimaryAction: boolean
    primaryActionLabel: string
    onPrimaryAction: () => void
    onInventory: () => void
    onBack: () => void
    onSecondaryAction?: () => void
    secondaryActionLabel?: string
    canBack: boolean
    cameraMode: boolean
}

function DirectionButton({
    direction,
    symbol,
    actions,
    repeat,
}: {
    direction: CardinalDirection
    symbol: string
    actions: DirectionActions
    repeat: boolean
}) {
    const action = actions[direction]
    const { pressed, pressProps } = useHeldAction(action?.run, repeat)
    return (
        <button
            type="button"
            className={`dpad-button dpad-${direction} ${pressed ? 'is-pressed' : ''}`}
            aria-label={
                actions[direction]
                    ? `Move ${direction} to ${actions[direction]?.label}`
                    : `No road ${direction}`
            }
            disabled={!action}
            {...pressProps}
        >
            {symbol}
        </button>
    )
}

function ActionButton({
    letter,
    className,
    action,
    disabled,
    label,
    repeat = false,
}: {
    letter: string
    className: string
    action?: () => void
    disabled?: boolean
    label: string
    repeat?: boolean
}) {
    const { pressed, pressProps } = useHeldAction(disabled ? undefined : action, repeat)
    return (
        <button
            type="button"
            className={`action-button ${className} ${pressed ? 'is-pressed' : ''}`}
            disabled={disabled}
            aria-label={label}
            {...pressProps}
        >
            {letter}
        </button>
    )
}

export function Gamepad({
    directions,
    canPrimaryAction,
    primaryActionLabel,
    onPrimaryAction,
    onInventory,
    onBack,
    onSecondaryAction,
    secondaryActionLabel = 'Choose destination',
    canBack,
    cameraMode,
}: GamepadProps) {
    return (
        <section className="gamepad" aria-label="Game controls">
            <fieldset className="dpad">
                <legend>Movement pad</legend>
                <DirectionButton
                    direction="up"
                    symbol="▲"
                    actions={directions}
                    repeat={cameraMode}
                />
                <DirectionButton
                    direction="left"
                    symbol="◀"
                    actions={directions}
                    repeat={cameraMode}
                />
                <div className="dpad-center" />
                <DirectionButton
                    direction="right"
                    symbol="▶"
                    actions={directions}
                    repeat={cameraMode}
                />
                <DirectionButton
                    direction="down"
                    symbol="▼"
                    actions={directions}
                    repeat={cameraMode}
                />
            </fieldset>
            <fieldset className="action-pad">
                <legend>Action buttons</legend>
                <ActionButton
                    letter="Y"
                    className="action-y"
                    disabled={!onSecondaryAction}
                    action={onSecondaryAction}
                    label={secondaryActionLabel}
                />
                <ActionButton
                    letter="X"
                    className="action-x"
                    action={onInventory}
                    label="Open inventory"
                />
                <ActionButton
                    letter="B"
                    className="action-b"
                    disabled={!canBack}
                    action={onBack}
                    label={cameraMode ? 'Zoom camera out' : 'Back'}
                    repeat={cameraMode}
                />
                <ActionButton
                    letter="A"
                    className="action-a"
                    disabled={!canPrimaryAction}
                    action={onPrimaryAction}
                    label={primaryActionLabel}
                    repeat={cameraMode}
                />
            </fieldset>
            <div className="gamepad-labels">
                <span>D-pad · {cameraMode ? 'camera' : 'move'}</span>
                <span>
                    A · {primaryActionLabel.toLowerCase()}
                    {cameraMode ? ' · B zoom out' : ' · Y targets · B back'}
                </span>
            </div>
            {cameraMode ? (
                <div className="camera-mode-label">Free camera · D-pad pans · A/B zoom</div>
            ) : (
                <div className="move-options" aria-live="polite">
                    {Object.entries(directions).map(([direction, choice]) => (
                        <span key={direction}>
                            {direction === 'up'
                                ? '▲'
                                : direction === 'down'
                                  ? '▼'
                                  : direction === 'left'
                                    ? '◀'
                                    : '▶'}{' '}
                            {choice.label} · {choice.kind}
                        </span>
                    ))}
                </div>
            )}
        </section>
    )
}
