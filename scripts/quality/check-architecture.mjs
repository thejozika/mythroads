import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { extname, join, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import { architectureConfig, frontendTiers } from './architecture.config.mjs'

const scriptDirectory = fileURLToPath(new URL('.', import.meta.url))
const repositoryRoot = resolve(scriptDirectory, '..', '..')

function normalize(path) {
    return path.split(sep).join('/')
}

function walk(directory) {
    if (!existsSync(directory)) return []
    return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
        if (entry.name.startsWith('.') || architectureConfig.ignoredDirectories.has(entry.name)) {
            return []
        }
        const path = join(directory, entry.name)
        return entry.isDirectory() ? walk(path) : [path]
    })
}

function tierFor(path) {
    return frontendTiers.find((tier) => path.endsWith(tier.suffix)) ?? null
}

function lineCount(source) {
    return source === '' ? 0 : source.split(/\r?\n/).length
}

function checkFileSize(path, source, findings, root) {
    const relativePath = normalize(relative(root, path))
    if (architectureConfig.lineLimitExceptions.has(relativePath)) return
    const isTest = /\.(test|spec)\.[jt]sx?$/.test(path)
    const limit =
        extname(path) === '.css'
            ? architectureConfig.maximumLines.stylesheet
            : isTest
              ? architectureConfig.maximumLines.test
              : architectureConfig.maximumLines.source
    const lines = lineCount(source)
    if (lines > limit) {
        findings.push(`${relativePath}: ${lines} lines exceeds the ${limit}-line limit`)
    }
}

function checkDevelopmentFragments(path, source, findings, root) {
    const relativePath = normalize(relative(root, path))
    const patterns = [
        [/\bconsole\.(log|debug|trace)\s*\(/, 'debug console call'],
        [/\bdebugger\s*;?/, 'debugger statement'],
        [
            /\b(TODO|FIXME|HACK|XXX)\b(?!\s*\([A-Z]+-\d+\)|[^\n]*(github\.com|#\d+))/,
            'untracked work marker',
        ],
    ]
    for (const [pattern, label] of patterns) {
        if (pattern.test(source)) findings.push(`${relativePath}: contains ${label}`)
    }
}

function checkTierContract(path, source, findings, root) {
    const relativePath = normalize(relative(root, path))
    if (
        (!relativePath.startsWith('src/') && !relativePath.startsWith('shared/')) ||
        architectureConfig.entryPointExceptions.has(relativePath)
    ) {
        return
    }
    if (!/\.[jt]sx?$/.test(path) || /\.(test|spec)\.[jt]sx?$/.test(path)) return
    const tier = tierFor(path)
    if (!tier) {
        findings.push(`${relativePath}: frontend file needs a taxonomy suffix`)
        return
    }
    if (tier.suffix === '.component.tsx' && /from\s+['"]convex\/react['"]/.test(source)) {
        findings.push(`${relativePath}: presentational components cannot access Convex`)
    }
    if (['.scene.tsx', '.object.tsx', '.effect.tsx', '.animation.ts'].includes(tier.suffix)) {
        if (/from\s+['"]convex\/react['"]/.test(source)) {
            findings.push(`${relativePath}: scenes cannot access Convex`)
        }
        if (/\b(window|document|localStorage|sessionStorage)\b/.test(source)) {
            findings.push(`${relativePath}: scenes cannot access browser UI globals`)
        }
    }
    if (tier.suffix === '.util.ts' && /from\s+['"](?:react|convex\/react)['"]/.test(source)) {
        findings.push(`${relativePath}: utilities must stay framework-independent`)
    }
    if (
        tier.suffix === '.system.ts' &&
        /from\s+['"](?:react|three|@react-three|convex)['/]/.test(source)
    ) {
        findings.push(
            `${relativePath}: gameplay systems must be deterministic and runtime-independent`,
        )
    }
    if (
        tier.suffix === '.geometry.ts' &&
        /from\s+['"](?:react|@react-three|convex)[/'"]/.test(source)
    ) {
        findings.push(`${relativePath}: geometry modules cannot depend on React or Convex`)
    }
    if (
        ['.material.ts', '.asset.ts'].includes(tier.suffix) &&
        /from\s+['"](?:react|convex\/react)['"]/.test(source)
    ) {
        findings.push(`${relativePath}: 3D resource modules cannot depend on React state or Convex`)
    }
    if (tier.suffix === '.hook.ts' && !/export\s+(?:function|const)\s+use[A-Z]/.test(source)) {
        findings.push(`${relativePath}: hook files must export a useX hook`)
    }

    const imports = [...source.matchAll(/import(?:\s+type)?[\s\S]*?from\s+['"]([^'"]+)['"]/g)]
    for (const match of imports) {
        const importedTier = tierFor(match[1])
        if (importedTier && importedTier.rank > tier.rank && !match[0].startsWith('import type')) {
            findings.push(
                `${relativePath}: ${tier.suffix} cannot depend on higher-tier ${importedTier.suffix}`,
            )
        }
    }
}

function checkDirectoryDensity(rootPath, findings, root) {
    const visit = (directory) => {
        const entries = readdirSync(directory, { withFileTypes: true })
        const files = entries.filter((entry) => entry.isFile() && !entry.name.startsWith('.'))
        if (files.length > architectureConfig.maximumFilesPerDirectory) {
            const relativePath = normalize(relative(root, directory))
            findings.push(
                `${relativePath}: ${files.length} files exceeds the ` +
                    `${architectureConfig.maximumFilesPerDirectory}-file folder limit`,
            )
        }
        for (const entry of entries) {
            if (entry.isDirectory() && !architectureConfig.ignoredDirectories.has(entry.name)) {
                visit(join(directory, entry.name))
            }
        }
    }
    visit(rootPath)
}

export function inspectRepository(root = repositoryRoot) {
    const findings = []
    for (const rootName of architectureConfig.sourceRoots) {
        const rootPath = join(root, rootName)
        if (!existsSync(rootPath)) continue
        checkDirectoryDensity(rootPath, findings, root)
        for (const path of walk(rootPath)) {
            if (
                !statSync(path).isFile() ||
                !architectureConfig.sourceExtensions.has(extname(path))
            ) {
                continue
            }
            const source = readFileSync(path, 'utf8')
            checkFileSize(path, source, findings, root)
            checkDevelopmentFragments(path, source, findings, root)
            checkTierContract(path, source, findings, root)
        }
    }
    return findings
}

function main() {
    const findings = inspectRepository()
    if (findings.length === 0) {
        console.log('Architecture check passed.')
        return
    }
    console.error(`Architecture check failed with ${findings.length} finding(s):`)
    for (const finding of findings) console.error(`- ${finding}`)
    process.exitCode = 1
}

if (resolve(process.argv[1] ?? '') === fileURLToPath(import.meta.url)) main()
