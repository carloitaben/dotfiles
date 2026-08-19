# Research: snippets with transforms (mini-first, React)

Type: research
Status: resolved

## Question

Survey nvim snippet engines that support programmatic transforms — e.g.
"grab current filename, transform to PascalCase, insert into the snippet" —
which Zed cannot do. Primary use case is React components (filename →
component name). Candidates: mini.snippets (mini-first; check whether it
supports Lua transforms), luasnip, snippets.nvim. Report: which support
arbitrary Lua transforms and template expansion, maintenance status, and a
concrete pick. mini-first preference.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/snippets-transforms.md`.

Only **LuaSnip** supports arbitrary Lua transforms in snippet templates
(`functionNode`/`dynamicNode` — read the buffer filename, transform to
PascalCase, insert). **mini.snippets** explicitly omits tabstop/variable
transforms (its docs: would need an ECMAScript regex engine it won't ship);
**nvim-snippets** delegates to native `vim.snippet` (no transform engine) and
is stale (last push 2024-07).

**Pick: LuaSnip.** The mini-first preference is overridden here — mini can't
do the filename→PascalCase transform the user wants for React components. A
mini.snippets + Lua function-loader workaround exists but only precomputes
static values (covers `Component.tsx` → name, not transforms of tabstop
input). Installs cleanly via `vim.pack.add`; `jsregexp` only needed for LSP
regex transforms, not the Lua-node approach.
