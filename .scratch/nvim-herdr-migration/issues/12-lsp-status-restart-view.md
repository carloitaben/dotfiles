# Research: LSP status/restart view (mini-first)

Type: research
Status: resolved

## Question

Survey nvim options for a Zed-style LSP status view: see active language
servers, per-server output/log, and restart one or all. User owns LSP via
lspconfig and already wants `cmd-r` parity (`editor::RestartLanguageServer`).
Stock `:LspInfo`/`:LspLog`/`:LspRestart` cover the basics; the want is a
*view* (popup/panel) of active servers + per-server output + restart.
Candidates should be lightweight; user prefers mini over snacks (finds snacks
bloated). Check whether mini.nvim has any primitive (e.g. mini.pick,
mini.extra) to build a small LSP panel on. Report a concrete pick and any
build-on-mini approach.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/lsp-status-view.md`.

Neovim has **no per-server log** — all servers share one `lsp.log`
(`:LspLog`), so Zed's per-server output view isn't natively achievable; the
best nvim can do is the shared log. Baseline `:LspInfo`/`:LspRestart` cover
the actions but have no picker. mini.nvim has **no LSP-status primitive**
(MiniExtra.pickers.lsp is navigation-only), but `MiniPick.start()` + registry
make a ~50-line custom panel straightforward. Closest off-the-shelf is
`msc5/lspinfo.nvim` (Telescope picker: servers + restart/stop/start +
capabilities, no log; 1 star, Telescope-only) — weak.

**Pick: build a small mini.pick picker** over `vim.lsp.get_clients()` with
restart/restart-all keymaps + an `:LspLog` action. Zero new deps, matches the
mini-first / `vim.pack.add` stack.
