# Task: disable Ghostty's native split/tab keybinds

Type: task
Status: resolved

## Question

Configure Ghostty so its native split/tab keybinds are disabled or left
unbound, since herdr is the sole multiplexer inside it (no tmux, no Ghostty
native splits/tabs to avoid muscle-memory collisions with herdr's prefix-key
bindings). Update Ghostty's config in this dotfiles repo accordingly.

## Answer

Native split/tab keybinds were already disabled: `.config/ghostty/config`
uses `keybind = clear` (Ghostty docs: "removes ALL keybindings up to this
point, including the default keybindings"), then re-adds only six —
`quit`, `copy_to_clipboard`, `paste_from_clipboard`, `clear_screen`,
`new_window`, `close_window`. None of those are split/tab actions, so no
native `new_split`/`goto_split`/`new_tab`/`goto_tab` bindings survive.

Change: added a two-line comment above `keybind = clear` recording the
intent (herdr is the sole multiplexer; no tmux, no Ghostty splits/tabs) so
the `clear` isn't mistaken for a leftover and split/tab binds aren't
re-added later.

Verified with `ghostty +validate-config` (Ghostty 1.3.1) — exits 0.
