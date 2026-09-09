import { BOARD, reachableRoutes } from '../../../shared/board.system'
import type { Player } from '../game.type'
import { BoardGround } from './BoardGround.object'
import { BoardPawn } from './BoardPawn.object'
import { BoardRoads } from './BoardRoads.object'
import { BoardSpace } from './BoardSpace.object'

type BoardWorldProps = {
    players: Player[]
    activePlayer?: Player
    remainingMoves: number
    selectedDestination?: number
    selectedPath?: number[]
}

export function BoardWorld({
    players,
    activePlayer,
    remainingMoves,
    selectedDestination,
    selectedPath,
}: BoardWorldProps) {
    const targeting = selectedDestination !== undefined
    const previewPath = selectedPath ?? []
    const previewPosition = selectedDestination ?? activePlayer?.position
    const previewRemaining = Math.max(0, remainingMoves - previewPath.length)
    const previewPrevious =
        previewPath.length > 1
            ? previewPath.at(-2)
            : previewPath.length === 1
              ? activePlayer?.position
              : undefined
    const reachable = new Set(
        targeting && previewPosition !== undefined
            ? previewRemaining === 0
                ? [previewPosition]
                : reachableRoutes(previewPosition, previewPrevious, previewRemaining).map(
                      (route) => route.destination,
                  )
            : [],
    )
    const selectedRoute =
        activePlayer && selectedPath ? [activePlayer.position, ...selectedPath] : undefined
    return (
        <>
            <BoardGround />
            <BoardRoads selectedRoute={selectedRoute} />
            {BOARD.map((node) => (
                <BoardSpace
                    key={node.id}
                    node={node}
                    reachable={reachable.has(node.id)}
                    selected={node.id === selectedDestination}
                />
            ))}
            {players.map((player, index) => (
                <BoardPawn
                    key={player._id}
                    player={player}
                    offset={index - (players.length - 1) / 2}
                    movementPoints={
                        targeting && player._id === activePlayer?._id ? previewRemaining : undefined
                    }
                />
            ))}
        </>
    )
}
