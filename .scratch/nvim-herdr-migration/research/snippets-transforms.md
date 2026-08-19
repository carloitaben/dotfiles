# Snippet engines: programmatic transforms (filename → PascalCase)

Question: which nvim snippet engine can take the current filename, transform it
(e.g. `foo_bar.tsx` → `FooBar`), and insert it into a snippet — the React
`Component.tsx` → `export function Component()` case. Zed cannot do this.
Evaluated against PRIMARY sources only.

## TL;DR

| Engine | Arbitrary Lua transform in template | LSP snippet compat | Maintained | verdict |
|---|---|---|---|---|
| mini.snippets | **No** | Yes (LSP syntax, deviations) | Yes (active) | workaround only |
| LuaSnip | **Yes** (`functionNode`/`dynamicNode`) | Yes (LSP + `jsregexp`) | Yes (active) | **pick** |
| nvim-snippets (garymjr) | **No** (delegates to `vim.snippet`) | Yes (VSCode/LSP via `vim.snippet`) | Stale (last push 2024-07) | no |

## mini.snippets (mini.nvim)

**Transforms: NOT supported.** Explicit in the docs, twice:

> "It does not support variable/tabstop transformations in default snippet
> session. This requires ECMAScript Regular Expression parser which can not be
> implemented concisely."

> "Variable transformations are not supported during snippet session. It would
> require interacting with ECMAScript-like regular expressions ... It may
> change in the future."

Source: https://github.com/nvim-mini/mini.nvim/blob/main/doc/mini-snippets.txt
(Notes section, and `MiniSnippets-syntax-specification` section).

mini.snippets only implements the LSP snippet syntax (tabstops, placeholders,
linked tabstops, choices, and variables like `$TM_FILENAME`) — no regex/transform
engine, so no `${TM_FILENAME/(.*)/${1:/pascalcase}/}` and no Lua callback inside
a snippet body.

**Workaround for the filename→PascalCase case (known-at-expand-time only):**
the loader/body can be a Lua *function* that computes static text at expand time.
mini.snippets runs function loaders on every expand via `default_prepare()`, and
snippets can be returned by `*.lua` files. A loader can read the buffer filename
(`vim.api.nvim_buf_get_name(cont.buf_id)` — `cont` is the `{buf_id, lang}`
context) and PascalCase it in Lua, returning a body with the name baked in as
static text. This handles *filename → component name*, but NOT transforms of
user-typed tabstop input (e.g. PascalCasing whatever is typed into `$1`).

Source for dynamic-loading advice:
https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-snippets.md
("To implement 'dynamic snippet' ... use `*.lua` file with function returning
snippet data") and the `MiniSnippets.default_prepare()` help.

**LSP compat:** Yes — implements LSP snippet syntax "with small deviations",
wider VSCode variable set, `TM_SELECTED_TEXT` via `"` register. Does NOT do LSP
variable transforms. Source: same doc, `MiniSnippets-syntax-specification`.

**Maintenance:** Active. `nvim-mini/mini.nvim`, ~9.5k stars, pushed 2026-08.
Source: https://api.github.com/repos/nvim-mini/mini.nvim

## LuaSnip (L3MON4D3/LuaSnip)

**Transforms: YES — arbitrary Lua.** Snippets are built from nodes; the two
relevant ones are:

- `functionNode` (`f(fn, argnode_refs)`): "insert text based on the content of
  other nodes using a user-defined function". `fn(args, parent, user_args)`
  returns the text. Re-evaluates when referenced nodes change.
- `dynamicNode` (`d(...)`): like `functionNode` but returns a whole `snippetNode`.

Plus `luasnip.extras` helpers (`lambda`, `match`, `rep`, `partial`,
`dynamic_lambda`, `nonempty`).

For filename→PascalCase, the typical approach is a `functionNode` whose `fn`
reads `vim.fn.expand('%:t:r')` (or `parent.snippet.env.TM_FILENAME`) and returns
the transformed string. Captures from a regex trigger are also available via
`snip.captures`.

Sources:
- FunctionNode: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#functionnode
- DynamicNode: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#dynamicnode
- Snippet env (`TM_FILENAME`): https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#data

**LSP compat:** Yes. Can parse LSP/TextMate snippet format via
`ls.parser.parse_snippet`, and supports LSP variable *transformations* (the
`${var/reg/repl/}` regex form) through the optional `jsregexp` dependency. Note:
`jsregexp` is required for LSP-style regex transforms (and the `"ecma"` trig
engine), but is NOT required for the Lua `functionNode`/`dynamicNode` approach.
Source: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md (Snippets context
`trigEngine = "ecma"` note, and the `LSP-snippets-transformations` reference).

**Maintenance:** Active. ~4.4k stars, pushed 2026-05.
Source: https://api.github.com/repos/L3MON4D3/LuaSnip

## nvim-snippets (garymjr)

**Transforms: NOT supported.** README states it "uses `vim.snippet` under the
hood for snippet expansion" and is VSCode-style-snippet → native `vim.snippet`
loading. No Lua transform API; `vim.snippet` itself does LSP variables but no
regex/transform engine.

Sources:
- https://github.com/garymjr/nvim-snippets/blob/main/README.md
- https://github.com/garymjr/nvim-snippets

**LSP compat:** Yes (VSCode/LSP snippet format via `vim.snippet`).

**Maintenance:** Effectively stale — last pushed 2024-07-17, 258 stars.
Source: https://api.github.com/repos/garymjr/nvim-snippets

Note: the repo name is `garymjr/nvim-snippets`, not `garymjr/snippets.nvim`
(the latter returns 404 on GitHub).

## Recommendation

**LuaSnip** is the only candidate that natively supports arbitrary Lua
transforms in snippet templates — which is what "filename → PascalCase inserted
into the snippet" requires in the general case (and the only one that can
transform user-typed tabstop input).

`mini.snippets` cannot do this: it deliberately omits transformations. The
mini-first preference can only be honored as a *workaround* — a Lua function
loader that bakes a precomputed PascalCase filename into the body. That covers
`Component.tsx` → component-name generation (filename is known at expand time)
but not arbitrary/tabstop transforms. If the sole need is filename-derived
component names, mini.snippets' workaround is viable and keeps the mini-first
stack. For real programmatic transforms, LuaSnip is required.

## `vim.pack.add` fit (no lazy.nvim)

- **mini.snippets** — first-class `vim.pack.add` support (Neovim ≥ 0.12), either
  standalone `vim.pack.add({ 'https://github.com/nvim-mini/mini.snippets' })`
  or the full `mini.nvim` library. Source:
  https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-snippets.md#installation
- **LuaSnip** — plain git plugin; clone with `vim.pack.add({
  'https://github.com/L3MON4D3/LuaSnip' })`, then `require('luasnip')` and
  `luasnip.setup()`. No lazy-specific wiring needed. `jsregexp` is a separate
  optional plugin (`bennypowers/nvim-regexplainer`-adjacent; actually
  `L3MON4D3/LuaSnip` installs it via `make install_jsregexp`) — not needed for
  Lua `functionNode` transforms.
- **nvim-snippets** — plain git plugin; `vim.pack.add({ 'https://github.com/garymjr/nvim-snippets' })`,
  then `require('nvim-snippets').setup()`. Requires Neovim ≥ 0.10 (for
  `vim.snippet`). Source: https://github.com/garymjr/nvim-snippets/blob/main/README.md
