# Zed → Ghostty + herdr + nvim migration

## Destination

A working Ghostty + herdr + nvim setup that fully replaces Zed as the daily coding
workflow: nvim as a pure editor (LSP, oil, Telescope), herdr as the sole home for
agents/dev-servers/worktree sessions, and Zed's diff-view and project-search
experience ported with equivalent feel (fold-like hunk handling, buffer-like
selection).

## Notes

- Personal dotfiles effort, not a team handoff — tickets execute the config
  changes as well as decide them, no separate implementation handoff.
- Repo: /Users/carlo/.dotfiles. nvim config at `.config/nvim/`, uses native
  `vim.pack.add` (no lazy.nvim). Zed config at `.config/zed/` stays on disk,
  untouched, unmaintained fallback — not deleted.
- Standing decisions (apply to every ticket below):
  - herdr owns every terminal/process/agent/dev-server; nvim never opens a
    `:terminal` split again.
  - One herdr tab/session per git worktree (not one nvim instance relocating).
  - Ghostty's native split/tab keybinds are disabled/unused — herdr is the sole
    multiplexer, no tmux underneath.
  - `nvim-tree` is being removed; `oil.nvim` is the file explorer.
  - Symbol keybinds mirror Zed's *actual* keymap (not VSCode's): `cmd-t` →
    workspace symbols, `cmd-shift-o` → document outline, both via Telescope
    (`lsp_workspace_symbols` / `lsp_document_symbols`).
  - herdr's native `zoomed` pane placement is the equivalent of Zed's
    Shift+Esc full-pane zoom — keep it.
  - Zed's git panel and agent panel are out of scope — user doesn't use them.
- Consult `/grilling` + `/domain-modeling` for any HITL ticket; `/research` for
  research tickets; `/prototype` for prototype tickets.

## Decisions so far

- [Task: herdr config baseline](issues/06-herdr-config-baseline.md) — `prefix=ctrl+b`, `zoom=["shift+esc","prefix+z"]` (Shift+Esc → herdr `zoomed` placement, confirmed working), agent sidebar rows showing state icon+text.
- [Task: wire cmd-t / cmd-shift-o symbol keybinds](issues/05-wire-symbol-keybinds.md) — `cmd-t` → `lsp_workspace_symbols`, `cmd-shift-o` → `lsp_document_symbols` in telescope.lua, mirroring Zed.
- [Task: remove nvim-tree](issues/04-remove-nvim-tree.md) — deleted `nvim-tree.lua` config + `vim.pack.del`'d the installed plugin (lockfile not hand-edited); oil.nvim already owns the file-explorer keybind.
- [Task: disable Ghostty's native split/tab keybinds](issues/03-ghostty-disable-native-multiplexing.md) — already disabled via `keybind = clear`; added explanatory comment, validated with `ghostty +validate-config`.
- [Research: nvim plugins for diff-as-buffer and search-as-buffer](issues/02-diff-search-as-buffer-plugins.md) — pick `dlyongemallo/diffview.nvim` (maintained fork) for diff-as-buffer, `grug-far.nvim` for search-as-buffer; both validated against the required feel.
- [Research: herdr + git worktree community patterns](issues/01-herdr-worktree-patterns.md) — herdr has native `herdr worktree create/open/list/remove`; agent can just call it directly, with `herdr-plus`/custom-plugin/`herdr-worktrunk` as escalating options if more automation is wanted.

## Not yet specified

- herdr session persistence/restore and notification sounds — left at defaults
  in ticket 06; low priority, decide once the workflow is in daily use.
- Ghostty config details beyond disabling native multiplexing (font/theme
  carryover from current terminal setup) — low priority, minor task once the
  rest is settled.

## Out of scope

- Zed's built-in git panel and agent panel — user doesn't use either.
- Uninstalling Zed or deleting its dotfiles — kept as an untouched fallback.
