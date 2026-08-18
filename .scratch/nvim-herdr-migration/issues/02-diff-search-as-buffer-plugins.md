# Research: nvim plugins for diff-as-buffer and search-as-buffer

Type: research
Status: resolved

## Question

Survey the current nvim plugin ecosystem for two Zed features to port:

1. A git-diff view that opens as a real, navigable buffer — not a modal — with
   fold-like hunk expand/collapse and normal buffer text selection (visual
   mode, yank, etc. work directly on the diff content). Candidates to check
   include `diffview.nvim` and any newer alternatives.
2. A project-wide search (and search-replace) UI that presents results as an
   editable buffer rather than a quickfix-only/modal view. Candidates to check
   include `grug-far.nvim` and any newer alternatives.

For each candidate, report: exact behavior (does it really let you fold/unfold
hunks like normal folds? can you select/yank diff or search-result text as if
it were plain buffer content? can you edit search results and apply as a bulk
replace?), maintenance status, and how closely each matches the described feel.
This report is an input to two later prototype tickets — no need to prototype
here, just survey and report findings with enough detail to make a pick.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/diff-search-as-buffer-plugins.md`
on branch `research/diff-search-as-buffer` (commit `bf984ae`).

**Diff-as-buffer** → `dlyongemallo/diffview.nvim` (actively-maintained fork;
the original `sindrets/diffview.nvim` is stale since 2024-08). Diff panes are
real buffers under native `foldmethod=diff`, so `zo`/`zc`/`za`/`zR`/`zM` are
literal Vim folds and all yank/visual-select/edit ops work as plain buffer
text. Index buffers are writable, stage-on-write. Closest match to Zed's feel.
Alternatives (`unified.nvim`, `mini.diff`) show diffs inline in the live
buffer via signs/virtual text, not as a dedicated editable diff document —
rejected as primary picks.

**Search-as-buffer** → `grug-far.nvim` (current community default; LazyVim
dropped `nvim-spectre` for it). Results are a real foldable, syntax-highlighted,
freely-editable buffer with a live replace-preview diff; three sync actions
(Sync Line / Sync All / Apply Next/Prev), and deleting a result line opts it
out of Sync All. Ripgrep-only (optional ast-grep for structural search),
needs Neovim ≥0.11. `nvim-spectre` (grug-far's predecessor) still works but
its README warns manual editing "may encounter strange behaviour" — weaker
match. Telescope+quickfix was considered and rejected — it's the "plain list"
pattern the user wants to escape.

**Recommendation for the prototype tickets**: install `dlyongemallo/diffview.nvim`
for diff review and `grug-far.nvim` for search/replace — both fit the existing
`vim.pack.add` + telescope/gitsigns/oil/lspconfig setup with no conflicting
plugin classes.
