# Task: capture Zed keybind patterns (time-boxed)

Type: task
Status: open

## Question

Per research 17 (Karabiner is a dead end), capture the user's actual keybind
usage while on Zed via a standalone CGEventTap keylogger, then cross-reference
against `keymap.json` to reconstruct which commands/keybinds he uses most.
Build the logger (Swift, no deps), have the user run it time-boxed (a few
days) while using Zed normally, then analyze the log. Deliverable: a
frequency list of Zed commands/keybinds actually used, feeding the "which
muscle-memory keybinds to carry into nvim" decision.

Note: requires Accessibility (Input Monitoring) permission for the terminal
that runs the logger; the logger only records keys while the frontmost app
matches the `zed` bundle-id filter (privacy — never logs other apps).

## How to run

- Tool: `tools/keylogger.swift` (compiled binary `tools/keylogger`).
- Rebuild if needed: `swiftc tools/keylogger.swift -o tools/keylogger`.
- Grant Input Monitoring once: System Settings → Privacy & Security → Input
  Monitoring → enable the terminal, then fully quit + relaunch it. Without
  this the tap can't be created.
- Run: `./tools/keylogger ~/zed-keys.log` (default filter `zed`). Append-only
  — safe to stop/start; each run seeks to the end of the existing file, so
  work + home captures can just accumulate (Ctrl+C to stop).
- To capture across machines, copy the log files together for analysis.

## Analysis (in progress — capture ongoing)

Cross-reference the log against `~/.config/zed/keymap.json` (merged with Zed's
default keymap) to reconstruct which commands/keybinds were actually used.
Feed the result into the "which muscle-memory keybinds to carry into nvim"
decision. Reopen this ticket or file a follow-up once a capture exists.

### First capture (work, one light day — 980 events)

Thin sample ("didn't code much"); held keys collapsed. Not definitive.

- Confirmed in use: `cmd+j` terminal toggle ×8 (ported), `ctrl+w` pane-nav ×7,
  `cmd+p` file open ×4, `cmd+shift+e` project panel ×3, `cmd+shift+g` lazygit
  ×3, `cmd+shift+p` palette ×1, `shift+esc` zoom ×1 (ported), `cmd+opt+o` ×1
  (the binding Zed broke).
- **Flag: `ctrl+w` + direction is the pane-nav muscle memory.** Zed uses
  `ctrl-w h/j/k/l`; herdr-splits.nvim maps `ctrl-h/j/k/l` directly, so in
  nvim `ctrl-w` hits nvim's internal window prefix instead. Needs a decision
  once more data is in.
- Excluded: `cmd+tab` ×11 (macOS app-switcher, not a Zed bind); `opt+\` held-key
  bursts collapsed 15→2 (typing artifact).
