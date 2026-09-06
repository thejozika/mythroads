export function identifiedDice(dice: number[]) {
    const occurrences = new Map<number, number>()
    return dice.map((sides) => {
        const occurrence = (occurrences.get(sides) ?? 0) + 1
        occurrences.set(sides, occurrence)
        return { id: `d${sides}-${occurrence}`, sides }
    })
}
