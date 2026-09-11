import type { WorldVisualId } from '../../../shared/world.type'

export const SPACE_VISUALS: Record<WorldVisualId, { color: string; icon: string }> = {
    'space.castle': { color: '#f7cf67', icon: '♜' },
    'space.combat': { color: '#ee5d62', icon: '⚔' },
    'space.event': { color: '#8d7cf6', icon: '?' },
    'space.armoury': { color: '#70879b', icon: '$' },
    'space.jeweller': { color: '#e58ab7', icon: '$' },
    'space.weapons': { color: '#cb744c', icon: '$' },
    'space.items': { color: '#61ad79', icon: '$' },
    'space.magic': { color: '#5a75d6', icon: '$' },
    'space.teleport': { color: '#60e1dc', icon: '✦' },
}
