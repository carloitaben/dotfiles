# Research: command-palette parity

Type: research
Status: resolved

## Question

Survey nvim options for a Zed-style command palette: search commands by name
AND description, and surface the keybind for the selected command so the user
learns keybinds over time. User tried telescope's command picker and found it
"doesn't feel as good". mini.clue already surfaces leader keys. Candidates:
mini.pick (mini-first), which-key.nvim, fzf-lua, snacks.nvim picker (likely
rejected as bloated), or a custom mini.pick integration. Report: does each
search descriptions? does each show the keybind inline? Report a concrete
pick, mini-first preferred.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/command-palette.md`.

No plugin fully reproduces Zed's palette: Neovim's command API returns names +
metadata but neither a keybinding nor (for built-ins) a description, so every
candidate splits into a name-only `commands` picker and a keybind-bearing
`keymaps` picker.

**Pick (mini-first, zero new deps): `MiniExtra.pickers.keymaps()`** as the
primary palette — searches name AND `desc`, shows the keybind inline
(`mode │ lhs │ desc`), runs on `<CR>` — alongside
`MiniExtra.pickers.commands()` for unmapped Ex commands (description in
preview only). mini.clue already surfaces both under leader. fzf-lua
reconstructs built-in descriptions (parses `doc/index.txt`) but costs an
`fzf` binary and still lacks command keybinds; snacks rejected as bloated.
