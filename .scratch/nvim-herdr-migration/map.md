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
- Repo: /Users/carloitaben/.dotfiles. nvim config at `.config/nvim/`, uses native
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
  - mini over snacks — snacks feels bloated; prefer mini.nvim primitives
    (mini.pick, mini.snippets) where possible, but fall back when mini can't
    cover the need (e.g. snippets transforms → LuaSnip).
  - No UI animation — snappy is the bar (no untokenized flashes, fast
    treesitter/LSP, no transition polish).
  - Inline git blame stays (gitsigns).
  - Snippets are used heavily for React components (filename → PascalCase).
- Consult `/grilling` + `/domain-modeling` for any HITL ticket; `/research` for
  research tickets; `/prototype` for prototype tickets.

## Done interactively (not ticketed)

Work done in-session, not yet a ticket — the "Decisions so far" list below only
covers ticketed work. See `HANDOFF.md` for fuller context.

- herdr upgraded to 0.8.2; prefix changed `ctrl+b` → `cmd+j` ("the terminal
  layer" — Zed's terminal keybind repurposed). CapsLock=Cmd makes cmd ergonomic,
  zsh ignores cmd, Ghostty forwards unbound cmd keys.
- vim-ctrl-w → herdr-prefix keymap mirror wired in `.config/herdr/config.toml`:
  focus `h/j/k/l`, split `v`/`s`, close `c`, new-tab `t`, close-tab `cmd+w`,
  move-to-tab `shift+t`, settings `,`, rename-tab `shift+m`; `zoom =
  ["shift+esc", "prefix+z"]`.
- nvim cleanup: `terminal.lua` + `zoom.lua` deleted (herdr owns terminals+zoom).
- nvim: `cmd+w` close-tab, `cmd+a` select-all, mini.clue `delay = 0`.
- `open-recent-repo` (`.config/herdr/bin/`, tracked) — fzf picker over
  `~/.config/herdr/recent_projects`, bound to `cmd+alt+o` as a direct herdr keybind.
- `carloitaben.recent-projects` herdr plugin (`.config/herdr/plugins/recent-projects/`,
  tracked; linked in bootstrap.sh) — subscribes to `workspace.created`, bumps the
  new workspace's cwd to the front of `recent_projects`. Catches `workspace create` /
  `worktree create` / agent-driven opens that the picker misses. (See `record.sh`.)
- One-time Zed history import into `recent_projects` (done; 91 distinct paths, ordered
  most-recent-first; `/Users/carlo` legacy paths kept as-is per user).
- gitsigns re-enabled (inline blame + hunk/keymap set uncommented).

## Decisions so far

- [Research: command-palette parity](issues/13-command-palette-parity.md) — MiniExtra.pickers.keymaps() + commands() (mini-first); no plugin does name+desc+keybind in one.
- [Research: image preview via ghostty graphics protocol](issues/14-image-preview.md) — `3rd/image.nvim` (kitty backend + ImageMagick), rasterizes SVG→PNG; snacks.image heavier, rejected.
- [Research: keybind/command usage tracking](issues/17-keybind-tracking.md) — Karabiner can't log keys; a time-boxed CGEventTap keylogger is the only path, if the palette SQLite data isn't enough.
- [Research: LSP status/restart view](issues/12-lsp-status-restart-view.md) — no per-server log exists; build a ~50-line mini.pick picker over `vim.lsp.get_clients()` with restart/restart-all + `:LspLog`.
- [Research: nvim local-history / undo-timeline](issues/11-local-history.md) — built-in `nvim.undotree` first; `jiaoshijie/undotree` only if diff-against-state is needed.
- [Research: snippets with transforms](issues/16-snippets-transforms.md) — LuaSnip is the only engine doing filename→PascalCase transforms; mini.snippets can't, so mini-first is overridden here.
- [Grill: Zed keep/ditch inventory](issues/10-zed-keep-ditch-inventory.md) — the "why" (state loss + agent-first workflow) and the full keep/ditch/improve inventory; grounds "equivalent feel" and spawns tickets 11–18.
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
