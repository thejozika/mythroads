/**
 * The small Markdown subset the Lean sources actually use.
 *
 * Module docs (`/-! -/`) and declaration docstrings (`/-- -/`) are written as Markdown: headings,
 * paragraphs, bullet and numbered lists, pipe tables, block quotes, inline code, emphasis, and
 * links. Nothing here tries to be a general Markdown implementation — it renders exactly those
 * constructs and escapes everything else, so a docstring can never inject markup into the page.
 *
 * Inline code spans are handed to `linkIdentifier` so that `` `Engine.Core` `` in prose becomes a
 * link to that declaration when one exists.
 */

/** Escapes the five characters that would otherwise be read as markup. */
export const escapeHtml = (text) =>
    text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')

const inlinePattern = /(`[^`]+`|\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\)|\*[^*\s][^*]*\*)/g

/** Renders one line of inline Markdown: code spans, bold, italics, and links. */
const inline = (text, linkIdentifier) =>
    text
        .split(inlinePattern)
        .map((piece) => {
            if (piece.startsWith('`') && piece.endsWith('`') && piece.length > 1) {
                const value = piece.slice(1, -1)
                const target = linkIdentifier?.(value)
                const code = `<code>${escapeHtml(value)}</code>`
                return target ? `<a class="xref" href="#${escapeHtml(target)}">${code}</a>` : code
            }
            if (piece.startsWith('**') && piece.endsWith('**') && piece.length > 3) {
                return `<strong>${escapeHtml(piece.slice(2, -2))}</strong>`
            }
            if (piece.startsWith('[')) {
                const split = piece.indexOf('](')
                const label = piece.slice(1, split)
                const href = piece.slice(split + 2, -1)
                if (!/^(https?:|#|\.)/.test(href)) return escapeHtml(piece)
                return `<a href="${escapeHtml(href)}">${escapeHtml(label)}</a>`
            }
            if (piece.startsWith('*') && piece.endsWith('*') && piece.length > 2) {
                return `<em>${escapeHtml(piece.slice(1, -1))}</em>`
            }
            return escapeHtml(piece)
        })
        .join('')

const isTableRow = (line) => line.trimStart().startsWith('|')
const isDivider = (line) => /^\s*\|[\s:|-]+\|\s*$/.test(line)
const cells = (line) =>
    line
        .trim()
        .replace(/^\||\|$/g, '')
        .split('|')
        .map((cell) => cell.trim())

/** Renders a pipe table, using the first row as the header when a divider follows it. */
const table = (rows, linkIdentifier) => {
    const header = isDivider(rows[1] ?? '') ? cells(rows[0]) : null
    const body = (header ? rows.slice(2) : rows).map(cells)
    const head = header
        ? `<thead><tr>${header.map((cell) => `<th>${inline(cell, linkIdentifier)}</th>`).join('')}</tr></thead>`
        : ''
    const rest = body
        .map(
            (row) =>
                `<tr>${row.map((cell) => `<td>${inline(cell, linkIdentifier)}</td>`).join('')}</tr>`,
        )
        .join('')
    return `<div class="scroller"><table>${head}<tbody>${rest}</tbody></table></div>`
}

const bulletPattern = /^\s*[*-]\s+/
const numberPattern = /^\s*\d+\.\s+/

/** Renders a run of list items, joining continuation lines onto the item they belong to. */
const list = (lines, ordered, linkIdentifier) => {
    const items = []
    for (const line of lines) {
        const marker = ordered ? numberPattern : bulletPattern
        if (marker.test(line)) items.push(line.replace(marker, ''))
        else if (items.length > 0) items[items.length - 1] += ` ${line.trim()}`
    }
    const rendered = items.map((item) => `<li>${inline(item, linkIdentifier)}</li>`).join('')
    return ordered ? `<ol>${rendered}</ol>` : `<ul>${rendered}</ul>`
}

/**
 * Renders a Markdown block into HTML.
 *
 * `linkIdentifier` maps an identifier written in a code span to the element id of its declaration
 * card, or returns nothing when the span does not name one.
 */
export const markdown = (text, linkIdentifier) => {
    const lines = text.replace(/\r/g, '').split('\n')
    const out = []
    let index = 0
    while (index < lines.length) {
        const line = lines[index]
        if (line.trim() === '') {
            index += 1
            continue
        }
        const heading = line.match(/^(#{1,6})\s+(.*)$/)
        if (heading) {
            const level = Math.min(heading[1].length + 2, 6)
            out.push(`<h${level}>${inline(heading[2], linkIdentifier)}</h${level}>`)
            index += 1
            continue
        }
        if (isTableRow(line)) {
            const rows = []
            while (index < lines.length && isTableRow(lines[index])) {
                rows.push(lines[index])
                index += 1
            }
            out.push(table(rows, linkIdentifier))
            continue
        }
        if (bulletPattern.test(line) || numberPattern.test(line)) {
            const ordered = numberPattern.test(line)
            const block = []
            while (index < lines.length && lines[index].trim() !== '') {
                block.push(lines[index])
                index += 1
            }
            out.push(list(block, ordered, linkIdentifier))
            continue
        }
        if (line.trimStart().startsWith('> ')) {
            const block = []
            while (index < lines.length && lines[index].trimStart().startsWith('> ')) {
                block.push(lines[index].trimStart().slice(2))
                index += 1
            }
            out.push(`<blockquote><p>${inline(block.join(' '), linkIdentifier)}</p></blockquote>`)
            continue
        }
        const paragraph = []
        while (
            index < lines.length &&
            lines[index].trim() !== '' &&
            !isTableRow(lines[index]) &&
            !/^#{1,6}\s/.test(lines[index]) &&
            !bulletPattern.test(lines[index]) &&
            !numberPattern.test(lines[index])
        ) {
            paragraph.push(lines[index].trim())
            index += 1
        }
        out.push(`<p>${inline(paragraph.join(' '), linkIdentifier)}</p>`)
    }
    return out.join('\n')
}
