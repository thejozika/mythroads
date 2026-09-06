import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

function main() {
    try {
        const input = JSON.parse(readFileSync(0, 'utf8'))
        const editedPath = input?.tool_input?.file_path
        if (typeof editedPath !== 'string' || !/\.(ts|tsx|js|jsx|css)$/.test(editedPath)) return

        const root =
            process.env.CLAUDE_PROJECT_DIR ??
            resolve(dirname(fileURLToPath(import.meta.url)), '..', '..')
        execFileSync('node', ['scripts/quality/check-architecture.mjs'], {
            cwd: root,
            encoding: 'utf8',
            stdio: ['ignore', 'pipe', 'pipe'],
        })
        execFileSync('npx', ['biome', 'check', editedPath], {
            cwd: root,
            encoding: 'utf8',
            stdio: ['ignore', 'pipe', 'pipe'],
        })
    } catch (error) {
        const output = [error?.stdout, error?.stderr].filter(Boolean).join('\n').trim()
        console.log(
            JSON.stringify({
                hookSpecificOutput: {
                    hookEventName: 'PostToolUse',
                    additionalContext: output.slice(0, 4000),
                },
            }),
        )
    }
}

main()
