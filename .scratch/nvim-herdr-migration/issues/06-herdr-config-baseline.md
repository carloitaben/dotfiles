# Task: herdr config baseline

Type: task
Status: resolved

## Question

Set up an initial `~/.config/herdr/config.toml` covering: a zoom keybind
equivalent to Zed's Shift+Esc (mapped onto herdr's native `zoomed` pane
placement), a prefix key choice (no tmux muscle memory to preserve, pick a
sensible default), and a sidebar row layout showing agent state
(blocked/working/done/idle). Session persistence/restore and notification
sounds are lower priority — leave at herdr defaults unless trivial to set now.

## Answer

Edited `.config/herdr/config.toml` (source-of-truth; live path
`~/.config/herdr/config.toml` is created by `stow .`). Added three blocks:

- `[keys] prefix = "ctrl+b"` — herdr's documented default. No tmux muscle
  memory to preserve, and it doesn't collide with the existing vim-style
  `ctrl+h/j/k/l` pane-nav chords. Matches docs/`prefix+?`/community examples.
- `[keys] zoom = ["shift+esc", "prefix+z"]` — Zed's Shift+Esc maps
  to herdr's native `zoomed` pane placement (toggle). `shift+esc` confirmed
  working live (Ghostty + herdr distinguish shift+esc from esc); `prefix+z`
  stays as the default.
- `[ui.sidebar.agents] rows = [["state_icon", "state_text", "agent"],
  ["workspace", "tab"]]` — agent state (blocked/working/done/idle) shown as
  icon + text on the first row, workspace/tab context on the second.

Session persistence/restore and notification sounds left at defaults (lower
priority, per ticket). Validated with `herdr config check` (via
`XDG_CONFIG_HOME` pointed at the repo): "config: ok".

Note: config not yet live — `~/.config/herdr/config.toml` symlink doesn't
exist; run `stow .` (or `stow -t ~ .config/herdr`).
