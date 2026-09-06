import type { CardinalDirection } from '../../../shared/controller-input.system'

type DirectionAction = { run: () => void; label: string; kind: string }
type DirectionActions = Partial<Record<CardinalDirection, DirectionAction>>

type GamepadProps = {
    directions: DirectionActions
    canPrimaryAction: boolean
    primaryActionLabel: string
    onPrimaryAction: () => void
    onInventory: () => void
    onBack: () => void
    inventoryOpen: boolean
}

function DirectionButton({
    direction,
    symbol,
    actions,
}: {
    direction: CardinalDirection
    symbol: string
    actions: DirectionActions
}) {
    return (
        <button
            type="button"
            className={`dpad-button dpad-${direction}`}
            aria-label={
                actions[direction]
                    ? `Move ${direction} to ${actions[direction]?.label}`
                    : `No road ${direction}`
            }
            disabled={!actions[direction]}
            onClick={actions[direction]?.run}
        >
            {symbol}
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
    inventoryOpen,
}: GamepadProps) {
    return (
        <section className="gamepad" aria-label="Game controls">
            <fieldset className="dpad">
                <legend>Movement pad</legend>
                <DirectionButton direction="up" symbol="▲" actions={directions} />
                <DirectionButton direction="left" symbol="◀" actions={directions} />
                <div className="dpad-center" />
                <DirectionButton direction="right" symbol="▶" actions={directions} />
                <DirectionButton direction="down" symbol="▼" actions={directions} />
            </fieldset>
            <fieldset className="action-pad">
                <legend>Action buttons</legend>
                <button
                    type="button"
                    className="action-button action-y"
                    disabled
                    aria-label="Y action"
                >
                    Y
                </button>
                <button
                    type="button"
                    className="action-button action-x"
                    onClick={onInventory}
                    aria-label="Open inventory"
                >
                    X
                </button>
                <button
                    type="button"
                    className="action-button action-b"
                    disabled={!inventoryOpen}
                    onClick={onBack}
                    aria-label="Back"
                >
                    B
                </button>
                <button
                    type="button"
                    className="action-button action-a"
                    disabled={!canPrimaryAction}
                    onClick={onPrimaryAction}
                    aria-label={primaryActionLabel}
                >
                    A
                </button>
            </fieldset>
            <div className="gamepad-labels">
                <span>D-pad · move</span>
                <span>A · {primaryActionLabel.toLowerCase()} &nbsp; X · inventory</span>
            </div>
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
        </section>
    )
}
