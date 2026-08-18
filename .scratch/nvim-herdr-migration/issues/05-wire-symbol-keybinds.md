# Task: wire cmd-t / cmd-shift-o symbol keybinds

Type: task
Status: resolved

## Question

In `.config/nvim/telescope.lua` (or wherever appropriate), bind `cmd-t` to
Telescope's `lsp_workspace_symbols` and `cmd-shift-o` to
`lsp_document_symbols`, mirroring Zed's actual default keymap
(`project_symbols::Toggle` on cmd-t, `outline::Toggle` on cmd-shift-o) rather
than VSCode's scheme.

## Answer

Added two keybinds to `.config/nvim/plugin/telescope.lua` (alongside the
existing `<D-*>` group):

- `vim.keymap.set('n', '<D-t>', builtin.lsp_workspace_symbols, ...)` — cmd-t
  → workspace symbols (`project_symbols::Toggle`).
- `vim.keymap.set('n', '<D-S-o>', builtin.lsp_document_symbols, ...)` —
  cmd-shift-o → document outline (`outline::Toggle`).

`builtin` (Telescope's builtins, `require('telescope.builtin')`) is already
in scope at line 80. Confirmed no prior binding for either key (grep across
`.config/nvim/`), syntax valid (`luac -p`).
