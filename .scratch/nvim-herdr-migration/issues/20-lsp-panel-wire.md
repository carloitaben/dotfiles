# Task: build mini.pick LSP status/restart panel

Type: task
Status: open

## Question

Per research 12, build a ~50-line mini.pick picker over `vim.lsp.get_clients()`
showing active language servers, with restart / restart-all keymaps and an
`:LspLog` action. Bind `cmd-r` to restart (Zed `editor::RestartLanguageServer`
parity — currently unbound in nvim) and add a keymap to open the panel. No new
deps; use mini.pick (already available via mini.nvim).
