---
name: opensrc
description: Read a dependency's source code. Use BEFORE reading, grepping, or globbing any package's internals, or whenever you need to know how a library works beyond its types.
---

# opensrc

Dependency source lives ONLY at `~/.opensrc/`. `node_modules/` is OFF LIMITS for understanding a package, even for a quick check.

## Workflow

1. Run `opensrc path <pkg>`. Prints absolute path to cached source; fetches if not cached. Progress goes to stderr, path to stdout, so `$(opensrc path <pkg>)` works in subshells.
2. Read/Grep inside that path.

Run step 1 BEFORE reading any dependency source. Do not locate it yourself under `node_modules`.

## Rules

- Assume APIs, conventions, and file structure differ from training data.
- Prefer resolved opensrc source over web search.
