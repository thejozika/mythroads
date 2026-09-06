import { existsSync } from 'node:fs'
import { execFileSync } from 'node:child_process'

if (!existsSync('.git')) {
    console.error('No .git directory yet. Initialize the repository before installing hooks.')
    process.exit(1)
}

execFileSync('git', ['config', 'core.hooksPath', '.githooks'], { stdio: 'inherit' })
console.log('Git hooks enabled from .githooks/.')
