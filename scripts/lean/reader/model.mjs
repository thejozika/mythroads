/**
 * Turns the `mythroads-docs` export into the shape the page renders.
 *
 * Three things happen here and nowhere else:
 *
 * 1. **Reading order.** Lean loads modules in a topological order of the import graph, and the
 *    exporter preserves it, so dependencies always precede dependents. That order is grouped into
 *    the five parts below, whose sequence is the editorial decision: foundations, then the one
 *    game definition, then the data it reads, then the language it is compiled through, then the
 *    programs that come out.
 * 2. **The declaration index.** Every declaration gets a stable element id, and a suffix index maps
 *    the way an identifier is *written* in Lean source (`State.mapPlayer`, `step`) back to the full
 *    name (`Mythroads.Engine.State.mapPlayer`). That index is what makes every identifier in a
 *    source listing a link.
 * 3. **Theorem statements.** A theorem's elaborated type is faithful but unsugared, so the card
 *    shows the author's own statement, sliced out of the source between the keyword and the proof.
 */

const parts = [
    {
        id: 'foundations',
        title: 'Foundations',
        root: null,
        blurb: 'Identities, the authorization policy, and the library root.',
        match: (name) => !/^Mythroads\.(Engine|Game|Convex|Backend)\b/.test(name),
    },
    {
        id: 'engine',
        title: 'The engine',
        root: 'Mythroads.Engine',
        blurb: 'One state, one event alphabet, one transition function, and its proofs.',
        match: (name) => name.startsWith('Mythroads.Engine'),
    },
    {
        id: 'rules-data',
        title: 'Rules data',
        root: null,
        blurb: 'The board, the catalogues, the matchup tables, and the generator the engine reads.',
        match: (name) => name.startsWith('Mythroads.Game'),
    },
    {
        id: 'embedding',
        title: 'The Convex embedding',
        root: 'Mythroads.Convex',
        blurb: 'A typed picture of the Convex programming model, and the printer that renders it.',
        match: (name) => name.startsWith('Mythroads.Convex'),
    },
    {
        id: 'backend',
        title: 'Generated backend programs',
        root: null,
        blurb: 'One module per emitted TypeScript file, written in the embedding.',
        match: (name) => name.startsWith('Mythroads.Backend'),
    },
]

const classical = new Set(['propext', 'Quot.sound', 'Classical.choice'])

/** The element id of a declaration card. */
export const declarationId = (name) => `d-${name.replaceAll('.', '-')}`

/** The element id of a module chapter. */
export const moduleId = (name) => `m-${name.replaceAll('.', '-')}`

/** The last `count` dot-separated segments of a name. */
const suffix = (name, count) => name.split('.').slice(-count).join('.')

/**
 * A theorem's statement as the author wrote it: everything between the keyword and the proof.
 *
 * The elaborated type is exported too and shown beside the proof, but it is printed without
 * notation — `Eq (step s env) …` rather than `step s env = …` — because the environment the
 * exporter assembles carries no notation delaborators. The source is both prettier and truer.
 */
export const statementOf = (declaration) => {
    const body = bodyOf(declaration)
    const marker = body.indexOf(':= by')
    const cut = marker === -1 ? body.indexOf(' :=') : marker
    return (cut === -1 ? body : body.slice(0, cut)).trimEnd()
}

/**
 * The declaration without its docstring.
 *
 * The exported source slice starts at the `/-- -/` block, because that is where Lean says the
 * declaration begins. The reader renders that docstring as prose immediately above the code, so
 * repeating it inside the listing would be noise.
 */
export const bodyOf = (declaration) => declaration.source.replace(/^\/--[\s\S]*?-\/\n/, '')

/** The proof of a theorem: everything after the statement. */
export const proofOf = (declaration) => bodyOf(declaration).slice(statementOf(declaration).length)

/** Whether every axiom this proof rests on is one of the three classical ones. */
export const isKernelChecked = (declaration) =>
    declaration.axioms.every((name) => classical.has(name))

/** Groups the exported modules into parts and indexes every declaration in them. */
export const buildModel = (exported) => {
    const modules = exported.modules
        .filter((module) => module.decls.length > 0 || module.prose.length > 0)
        .map((module) => ({
            ...module,
            id: moduleId(module.name),
            file: `proofs/${module.file.replace(/^\.\//, '')}`,
            short: module.name.replace(/^Mythroads\.?/, '') || 'Mythroads',
            theorems: module.decls.filter((d) => d.kind === 'theorem'),
            definitions: module.decls.filter((d) => d.kind !== 'theorem'),
        }))

    const grouped = parts.map((part) => {
        const members = modules.filter((module) => part.match(module.name))
        const root = members.findIndex((module) => module.name === part.root)
        const ordered =
            root > 0 ? [members[root], ...members.filter((_, i) => i !== root)] : members
        return { ...part, modules: ordered }
    })

    const byName = new Map()
    const bySuffix = new Map()
    for (const module of modules) {
        for (const declaration of module.decls) {
            const entry = { name: declaration.name, module: module.name, kind: declaration.kind }
            byName.set(declaration.name, entry)
            const segments = declaration.name.split('.').length
            for (let count = 1; count <= segments; count += 1) {
                const key = suffix(declaration.name, count)
                if (!bySuffix.has(key)) bySuffix.set(key, [])
                bySuffix.get(key).push(entry)
            }
        }
    }

    /**
     * Resolves an identifier as written to a declaration id.
     *
     * `context` is the module the identifier was written in; a name visible there wins over the
     * same suffix declared elsewhere, which is what makes `State` inside `Engine.Step` link to
     * `Mythroads.Engine.State` rather than to `Mythroads.Backend.Combat.State`.
     */
    const resolve = (identifier, context) => {
        const candidates = byName.has(identifier)
            ? [byName.get(identifier)]
            : (bySuffix.get(identifier) ?? [])
        if (candidates.length === 0) return null
        const local = candidates.find((entry) => entry.module === context)
        if (local) return declarationId(local.name)
        if (context) {
            const namespaced = candidates.find((entry) => context.startsWith(entry.module))
            if (namespaced) return declarationId(namespaced.name)
        }
        const unique = candidates.length === 1 ? candidates[0] : null
        return unique ? declarationId(unique.name) : null
    }

    const counts = {
        modules: modules.length,
        declarations: modules.reduce((sum, module) => sum + module.decls.length, 0),
        theorems: modules.reduce((sum, module) => sum + module.theorems.length, 0),
        lines: modules.reduce((sum, module) => sum + module.lines, 0),
    }

    return { toolchain: exported.toolchain, parts: grouped, modules, resolve, counts }
}
