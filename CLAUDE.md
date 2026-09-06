# Dice RPG

A Dokapon Kingdom-inspired game (board-game RPG hybrid).

## Repository layout

- `documents/` — knowledge base. Organized into subfolders by element (one folder per topic — combat, board, characters, items, etc.). Authoritative design notes and specs live here. Consult before making design or implementation decisions.
- `sources/` — raw source material: web research, PDFs, scraped pages, screenshots, and other reference material gathered while researching the original game or related systems. Inputs for the knowledge base, not the knowledge base itself.

## Engineering workflow

Read `AGENTS.md` and `documents/engineering/code-architecture.md` before creating source files.
Every frontend file uses a role suffix. The edit hook in `.claude/settings.json` reports taxonomy,
size, folder-density, and Biome findings after writes. Run `npm run check` before handing work off.

<!-- convex-ai-start -->

This project uses [Convex](https://convex.dev) as its backend.

When working on Convex code, **always read
`convex/_generated/ai/guidelines.md` first** for important guidelines on
how to correctly use Convex APIs and patterns. The file contains rules that
override what you may have learned about Convex from training data.

Convex agent skills for common tasks can be installed by running
`npx convex ai-files install`.

<!-- convex-ai-end -->
