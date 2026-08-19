# Research: nvim local-history / undo-timeline

Type: research
Status: resolved

## Question

Survey nvim options for an IntelliJ/undotree-style local file history — a
browseable timeline of past versions of a file, independent of git. User
already has `undofile = true` (persistent undo); the want is the *browse
past versions* view, not blind undo. Candidates: undotree.nvim and any
newer/mini-first alternatives. Report: exact behavior (timeline of saved
states? diff against a picked state?), maintenance status, and how well each
fits a "pure editor" setup. mini-first preference (mini over snacks — user
finds snacks bloated); note whether mini.nvim has any primitive to build on.
Report a concrete pick.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/local-history.md`.

Neovim ≥ 0.12 ships a built-in `:Undotree` (`:packadd nvim.undotree`) — a
zero-dependency textual undo-tree browser that maps cursor movement to
`:undo {seq}`. Gives the browseable timeline; no diff view, no saved-state
markers. `mbbill/undotree` (original) has a real diff panel + `s`/`S` save
markers but is dormant (last release 2019, Vim-script). `jiaoshijie/undotree`
is the active Lua rewrite (MIT, 2026-02) adding a diff/preview window on the
same persistent-undo model. `atone.nvim` is feature-richest but GPL-3.0 and
new. mini.nvim has no local-history/undo-tree module.

**Pick: built-in `nvim.undotree` first** (zero deps, ships in 0.12); add
`jiaoshijie/undotree` only if the diff-against-state view turns out to be
needed in daily use.
