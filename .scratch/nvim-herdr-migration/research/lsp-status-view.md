# LSP Status View in Neovim (Zed-style)

Goal: a view of active language servers + per-server output/log + restart one/all,
parity with Zed's `editor::RestartLanguageServer`. LSP owned via nvim-lspconfig.
Target: lightweight, works with `vim.pack.add` (no lazy.nvim), mini.nvim preferred.

## Key architectural fact

Neovim has **no per-server log**. All LSP traffic is written to a **single shared
`lsp.log`** file, controlled globally by `vim.lsp.set_log_level()` and opened by
`:LspLog` (the file lives in `stdpath('state')`). Per-server separation, like Zed
gives you, is **not natively available** — you either grep the shared log for a
server's name, or launch each server with its own `--log-file`/`--log-file` flag in
its `cmd`. Any plugin claiming "per-server output" is filtering the shared file, not
reading a per-server stream.

Sources: `:help vim.lsp.set_log_level`, `:help LspLog`; https://neovim.io/doc/user/lsp/

---

## 1. Baseline — built-in + nvim-lspconfig

- `:LspInfo` (alias `:checkhealth vim.lsp`) — floating window listing **active** and
  **configured** clients: name, id, root dir, filetypes, `cmd`. Read-only, no actions.
- `:LspLog` — opens the shared `lsp.log`.
- `:LspRestart` / `:LspStart` / `:LspStop` (nvim-lspconfig); on Nvim 0.12+ these are
  upstreamed as `:lsp restart`, `:lsp stop`, `:lsp enable`, `:lsp disable`.
  `:lsp restart [client_name]` restarts one or (no arg) all clients attached to the
  current buffer.

Covers the *actions* fully (restart one/all, view servers, view log) but has **no
interactive picker** — `:LspRestart` takes a name argument, it doesn't present a
selectable list. This is the gap a nicer view fills.

Sources: https://github.com/neovim/nvim-lspconfig (README command table);
https://neovim.io/doc/user/lsp/ (`:lsp restart`, `:lsp stop`); upstreaming tracked in
https://github.com/neovim/neovim/issues/28479

**Fit:** excellent for correctness, zero dependencies, but no panel/UI.

---

## 2. mini.nvim — is there a primitive? (explicit check requested)

**No dedicated LSP-server-status primitive exists.** The only LSP-adjacent piece is
`MiniExtra.pickers.lsp()`, which provides pickers for *navigation* methods —
`declaration`, `definition`, `document_symbol`, `implementation`, `references`,
`type_definition`, `workspace_symbol`, `workspace_symbol_live` — plus
`MiniExtra.pickers.diagnostic()`. Nothing lists running clients, nothing restarts
them, nothing shows the log.

However, **mini.pick is a general-purpose picker with a custom-source API**, so a
small LSP panel is buildable on it:

- `MiniPick.start()` takes a custom `source` table with `items`, `name`, `choose`,
  `choose_marked`, `show`, `preview`.
- Custom pickers can be registered into `MiniPick.registry` and invoked via
  `:Pick <name>`.

A ~50-line picker can list `vim.lsp.get_clients()` (name, id, root, attached buffers),
map `choose` to `vim.lsp.stop_client()`/restart, and `choose_marked` to restart all
selected; a separate keymap opens `:LspLog`. This is the natural home for a
`vim.pack.add` setup that already uses mini.

Sources: https://nvim-mini.org/mini.nvim/readmes/mini-extra
(`MiniExtra.pickers.lsp` scope list); https://nvim-mini.org/mini.nvim/readmes/mini-pick
(`MiniPick.start()`, `MiniPick.registry`, source fields).

Maintenance: **actively maintained** — nvim-mini/mini.nvim, 9.4k stars, last push
2026-08-15 (days before this writeup).

**Fit:** no off-the-shelf panel, but the best substrate to build one on; zero new
dependencies given mini is already the preferred stack.

---

## 3. msc5/lspinfo.nvim — closest off-the-shelf "view + restart"

A **Telescope picker** over running LSP clients with real-time preview updates
(client name, id, root, attached buffers + diagnostic counts, status/initialized) and
per-entry keymaps: **restart** (`r`), **stop** (`s`), **start** (`t`), **capabilities**
(`c`). Registered as `:LSPInfo`.

- Shows running servers: **yes**.
- Per-server log: **no**.
- Restart one / all: restart one via keymap; all requires marking multiple (stop/start
  per entry). No dedicated "restart all".

Dependencies: telescope.nvim + plenary.nvim. No lazy.nvim required (plain vim-plug /
`vim.pack.add` shown in README), but it drags in the Telescope stack.

Maintenance: **very small/single-author but recent** — 1 star, 0 forks, created
2025-08, last push 2026-01-28 (per GitHub API). No open issues.

Source: https://github.com/msc5/lspinfo.nvim

**Fit:** best off-the-shelf match for the *view + restart* half, but Telescope-only
(conflicts with a mini-first, no-Telescope setup) and no log half.

---

## 4. eetann/lsp-dev.nvim — log-focused, no restart

Commands: `:LspDev showLog` (log viewer), `:LspDev deleteLog`, `:LspDev
changeLogLevel`, `:LspDev showCapabilities` (selects from active servers, shows their
capabilities).

- Shows running servers: only as a selection list for capabilities.
- Per-server log: **no** — shows the single shared `lsp.log`.
- Restart: **no**.

Dependency: nui.nvim. Maintenance: **dormant** — 0 stars, last push 2025-02-12.

Source: https://github.com/eetann/lsp-dev.nvim

**Fit:** covers the log-viewer itch only; no restart; nui.nvim dependency; dead.

---

## 5. nvim-lua/lsp-status.nvim — statusline library, not a panel

Utility functions for **statusline** components: `diagnostics()`, `messages()`
(progress), `current_function()`, `status()`. Requires per-client `on_attach(client)`
and `capabilities` wiring. No server list, no restart, no log.

Maintenance: **effectively dormant** — last commit 2022-08-31, 26 open issues
(654 stars but stale).

Source: https://github.com/nvim-lua/lsp-status.nvim

**Fit:** not relevant; it's a statusline display, not a panel. Only useful if you also
want a live "servers busy" indicator in the statusline.

---

## 6. Ruled out (checked, not a fit)

- **lspsaga.nvim** (`nvimdev/lspsaga.nvim`) — large LSP UI suite (finder, rename,
  call hierarchy, code action, hover). No server-status/restart panel; heavy, opposite
  of "lightweight". Source: https://nvimdev.github.io/lspsaga/
- **LspUI.nvim** (`jinzhongjia/lspui.nvim`) — 13-module LSP UI wrapper inspired by
  lspsaga; same heaviness, no server lifecycle panel.
- **telescope / fzf-lua LSP builtins** — only navigation (references, definitions,
  symbols, diagnostics). Neither has a server-status/restart picker. Sources:
  https://github.com/nvim-telescope/telescope.nvim (LSP pickers table);
  https://github.com/ibhagwan/fzf-lua (LSP provider list).

---

## Recommendation

**Build on mini.pick** (a ~50-line custom picker registered in `MiniPick.registry`):

1. `items` = `vim.lsp.get_clients()` (name, id, root_dir, attached bufnrs, status).
2. `choose` = restart that client (`vim.lsp.stop_client` + re-enable, or `:lsp restart
   <name>`); `choose_marked` = restart all marked; a `stop` keymap too.
3. A "log" action opens `:LspLog` (the shared file) or `grep`s it for the selected
   server's name — the only honest "per-server output" available without per-server
   `--log-file` flags.

Rationale: zero new dependencies, satisfies the mini-over-snacks preference and
`vim.pack.add` (mini ships as a plain repo, no lazy needed), and the actions already
exist natively (`:lsp restart`). If a ready-made UI is preferred **and** Telescope is
acceptable, `msc5/lspinfo.nvim` is the closest drop-in for view + restart (accept the
missing log half). Don't adopt lsp-status.nvim or lsp-dev.nvim (wrong scope / dormant).
