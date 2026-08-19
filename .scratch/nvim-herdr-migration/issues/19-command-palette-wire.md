# Task: wire command palette (MiniExtra keymaps + commands)

Type: task
Status: open

## Question

Wire up the command palette per research 13: use `MiniExtra.pickers.keymaps()`
as the primary palette (searches name AND `desc`, shows the keybind inline,
runs on `<CR>`) alongside `MiniExtra.pickers.commands()` for unmapped Ex
commands. mini.nvim is already installed via `vim.pack.add`; require
`mini.extra` and bind the pickers to a keymap (`cmd-shift-p`, Zed's palette
binding — unbound in nvim today). Verify the keybind-surfacing behavior.
