export function gameCommand<const Event>(event: Event) {
    return { commandId: crypto.randomUUID(), event }
}
