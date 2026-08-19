# Local File History in Neovim (undotree-style)

Question: options for a browseable timeline of past file versions, independent of git.
Context: `undofile = true` already enabled. User wants the *browse/diff* view, not blind undo.
Strongly prefers mini.nvim; finds snacks.nvim bloated.

## Two distinct models

1. **Undo-tree visualizers** — build directly on Neovim's persistent undo (`undofile`). No extra storage; nothing written to disk beyond what `undofile` already does. This is the "IntelliJ local history / undotree" model.
2. **Snapshot-on-save** — write a separate copy of the file on every `:w`. Independent of undo, but introduces a second store to manage (and often a git repo or a picker dependency).

The user's `undofile = true` setup maps to model 1; model 2 is included for completeness but is a different (redundant) mechanism.

---

## Candidate 1 — Built-in `:Undotree` (nvim.undotree)  ★ default

**Behavior.** Ships with Neovim ≥ 0.12 as a dist opt-plugin (`runtime/pack/dist/opt/nvim.undotree`). Not auto-loaded; enable with `:packadd nvim.undotree`, then `:Undotree` (or `require('undotree').open`). Renders the undo tree as text: each node is a `seq` number + a relative/absolute timestamp, with ASCII branch edges. Moving the cursor in the window applies `:undo {seq}` to the source buffer (live state preview). Source confirms the mechanism: a `CursorMoved` autocmd runs `vim.cmd.undo { meta[row] }` (undotree.lua:383-392), and node lines are drawn as `seq (time)` (undotree.lua:183-191).

- **Timeline of saved states?** Partial. Shows every undo *change* (each seq) with timestamps, not just saves. It does **not** mark "saved" states with `s`/`S` the way mbbill does.
- **Diff against a picked state?** **No.** No diff panel. "Preview" is achieved by actually undoing the buffer to the hovered seq; no side-by-side or inline diff.
- **Persistent undo integration?** Direct — reads the live undo tree, so it automatically sees anything `undofile` has persisted across sessions.
- **Config surface:** `open({ bufnr, winid, command, title })` only. No colorscheme/keys customization.

**Maintenance.** Added by altermo, merged 2025-10-07 (neovim/neovim PR #35627, commit 9e1d3f48); documented in `:h package-undotree`. User is on `v0.13.0-dev`, so it is present.

**Pure-editor fit.** Best possible: zero plugins, zero dependencies, ~400 LoC runtime file.

Sources: https://github.com/neovim/neovim/pull/35627 · https://neovim.io/doc/user/plugins/#package-undotree · https://neovim.io/doc/user/undo/ · local source `/opt/homebrew/Cellar/neovim/HEAD-7fff439/share/nvim/runtime/pack/dist/opt/nvim.undotree/lua/undotree.lua`

---

## Candidate 2 — mbbill/undotree (the original)

**Behavior.** Vim-script plugin that visualizes the undo tree and lets you browse/switch branches. Commands `:UndotreeToggle`, `:UndotreeShow`, `:UndotreeFocus`, `:UndotreePersistUndo`. Markers: current state `> n <`, next `{ n }`, most-recent `[ n ]`, saved `s` / most-recent-saved `S`. Has a real **diff panel** (`D` toggles it; `=` sets a diff marker to diff any two states), rendered with the external `g:undotree_DiffCommand` (default `diff`). `?` shows in-window help.

- **Timeline of saved states?** Yes — `s`/`S` markers denote writes; states are sorted by timestamp.
- **Diff against a picked state?** **Yes** — a diff panel below the tree; can diff current-vs-marked seq (autoload/undotree.vim `ActionDiffMark`/`UpdateDiff`).
- **Persistent undo?** Explicitly documented: plugin never writes to disk; relies on `undofile` (`:h persistent-undo`), plus a cleanup option.
- **Pure-editor fit.** Pure Vim script, no deps, lightweight, runs only when needed — but Vim-script (not Lua), config via `g:` globals.

**Maintenance.** Last tagged release **v6.1 (2019-10-12)**; repo still receives occasional commits (last push 2026-08), 44 open issues, 4.5k stars. De facto stable-but-dormant. BSD-3-Clause.

Sources: https://github.com/mbbill/undotree · https://github.com/mbbill/undotree/blob/master/doc/undotree.txt · https://github.com/mbbill/undotree/blob/master/autoload/undotree.vim · https://github.com/mbbill/undotree/releases

---

## Candidate 3 — jiaoshijie/undotree (Lua rewrite)

**Behavior.** Pure-Lua re-implementation ("primarily a visualizer for Neovim's internal undo tree"). Features: tree structure viz, **diff preview between current state and the state under cursor**, commands to clear history / rename file, two tree styles (`compact`/`legacy`), multiple window layouts (`left_bottom`/`left_left_bottom`), floating-diff option (`float_diff`), lazy-loadable. Default keymaps: `j/k` move, `gj` parent, `J/K` move-and-apply, `<cr>` undo to state, `p` switch to diff/preview window, `S` re-parse.

- **Timeline?** Yes — tree of states with a preview window.
- **Diff?** **Yes** — a dedicated diff/preview buffer comparing hovered state vs current.
- **Persistent undo?** Inherits it — visualizes Neovim's internal undo tree, so `undofile` content is included automatically.

**Maintenance.** Active: created 2022, last push **2026-02-25**, 8 contributors, 341 stars, 1 open issue. MIT.

Sources: https://github.com/jiaoshijie/undotree · https://github.com/jiaoshijie/undotree/blob/main/README.md

---

## Candidate 4 — XXiaoA/atone.nvim (modern)

**Behavior.** "Modern undotree plugin" written against nvim 0.12. Compared to built-in `:Undotree`: adds tree visualization (standard + compact), **Treesitter-highlighted + word-level inline diff preview**, persistent numbered/named/fuzzy-findable node **marks**, custom labels, auto-attach to buffers, high customizability. Commands `:Atone open|toggle|close|focus`. Its README explicitly positions it as "built-in is great — atone is for those who want more" and ships a feature table vs nvim 0.12 `:undotree`.

- **Timeline?** Yes. **Diff?** Yes, stronger than any other (word-level inline, Treesitter colors).
- **Persistent undo?** Same model — rides the undo tree.

**Maintenance.** Active: created 2025-10-08, last push **2026-04-11**, 172 stars. **GPL-3.0** (copyleft — worth noting vs MIT/BSD).

Sources: https://github.com/XXiaoA/atone.nvim

---

## Candidate 5 — vim-mundo (brief)

Python-based rewrite of undotree (mentioned as the original Gundo lineage). Requires Python host + Vim/Neovim Python integration, which is heavier than the Lua/script options and contrary to a lean setup. Not recommended here.

Source: https://github.com/simnalamburt/vim-mundo (referenced in sanfusu/neovim-undotree README)

---

## mini.nvim — explicit check  ★ the user's preference

**No local-history / undo-tree module exists.** The full module list has `mini.diff` (diff hunks vs a reference, default Git index), `mini.bracketed` (square-bracket navigation), `mini.files`, `mini.pick`, etc. — no undo-tree browser. Closest primitives, both insufficient as a "browse past versions" view:

- **`mini.bracketed.undo()`** — linear undo navigation target (`[u`/`]u`, `[U`/`]U`). Cycles through a *tracked linear* undo history (it records states as you undo/redo, via `MiniBracketed.register_undo_state()`). It is not a tree view, shows no timestamps, no saved markers, no diff.
- **`mini.diff`** — a `config.source` is pluggable (`set_ref_text()`), so one *could* theoretically point it at a chosen undo state or a snapshot file to get inline hunks. But there is **no built-in source for undo states or local history**, and no recipe for this. Building it is a from-scratch mini-module, not a primitive.

So mini.nvim does **not** provide a turnkey local-history view, and only gives raw building blocks (`MiniDiff.set_ref_text`, `vim.fn.undotree`) for a DIY one.

Sources: https://nvim-mini.org/mini.nvim/doc/mini-nvim.html · https://nvim-mini.org/mini.nvim/readmes/mini-diff · https://nvim-mini.org/mini.nvim/doc/mini-bracketed.html

---

## Alternative model — snapshot-on-save (for completeness)

These write a copy per save, independent of undo — a genuinely different approach, and mostly redundant when `undofile` is already on:

- **dinhhuy258/vim-local-history** — Python remote plugin; copies to `.local-history/` on save; `j/k` older/newer, `r` diff, `Enter` revert. Depends on `:UpdateRemotePlugins`.
- **yukimemi/silentsaver.nvim** — pure-Lua; async timestamped backups under `stdpath('state')`; `:SilentSaverOpen` browse (quickfix/`vim.ui.select`), `:SilentSaverDiff`.
- **dawsers/file-history.nvim** — git-backed history repo + **snacks.nvim** picker (needs git + snacks — conflicts with user's no-snacks preference).
- **m42e/lgh.nvim** — local git history + telescope.

Sources: https://github.com/dinhhuy258/vim-local-history · https://github.com/yukimemi/silentsaver.nvim · https://github.com/dawsers/file-history.nvim · https://github.com/m42e/lgh.nvim

---

## Recommendation

**Use the built-in `nvim.undotree` now; add `jiaoshijie/undotree` only if the missing diff preview matters.**

The built-in `:Undotree` is the best "pure editor" answer: already shipped (user is on 0.13-dev), zero deps, browseable timeline with timestamps. Its one real gap versus the plugin options is **no diff view** (preview = actual undo to hovered state).

If a diff-against-state view is wanted (the IntelliJ feel), pick **jiaoshijie/undotree** over mbbill: same persistent-undo model, actively maintained (MIT, last push 2026-02), pure Lua, and it adds the diff/preview window that the built-in lacks — without pulling in snacks or git. atone.nvim is feature-richest but GPL-3.0 and younger; mbbill/undotree is mature but effectively dormant (last release 2019) and Vim-script. There is no mini.nvim primitive to lean on, so a mini-only solution would have to be hand-built.
