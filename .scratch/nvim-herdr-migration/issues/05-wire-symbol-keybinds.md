# Task: wire cmd-t / cmd-shift-o symbol keybinds

Type: task
Status: open

## Question

In `.config/nvim/telescope.lua` (or wherever appropriate), bind `cmd-t` to
Telescope's `lsp_workspace_symbols` and `cmd-shift-o` to
`lsp_document_symbols`, mirroring Zed's actual default keymap
(`project_symbols::Toggle` on cmd-t, `outline::Toggle` on cmd-shift-o) rather
than VSCode's scheme.
