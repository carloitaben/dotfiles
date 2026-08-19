# Research: keybind/command usage tracking via Karabiner

Type: research
Status: resolved

## Question

The user wants to discover which Zed commands/keybinds he actually uses, to
decide which muscle-memory keybinds to carry into nvim. Zed only logs
command-palette invocations (SQLite table command_invocations), never
keybind-run commands, and has no plugin/extension hook — capturing keybinds
via Zed itself needs a source patch (ruled out). The user has
Karabiner-Elements installed. Survey whether Karabiner can log actual key
presses (its event log / output to file) and whether that can be
cross-referenced against Zed's keymap.json to reconstruct command usage.
Report concrete options (karabiner eventviewer/log export, any CLI, any
community config) with tradeoffs, and whether this is worth doing vs. just
the palette SQLite data already gathered.

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/keybind-tracking.md`.

Karabiner-Elements has **no key-event logging/export** of any kind: its log
files hold only errors, `karabiner_cli` has no key-stream option, and the
author declined to add logging (issue #2277). EventViewer is GUI-only with no
export and no backing file. The only Karabiner-native route is a hacky
`from.any key_code → shell_command` rule, but `shell_command` gets no key
argument and spawns a process per keystroke — discouraged.

**Verdict: no Karabiner path.** To capture real keybind habits, run a short
time-boxed standalone `CGEventTap` keylogger (pqrs-org/osx-event-observer-examples
or a community keylogger), cross-referenced against Zed's keymap.json. That
cross-reference is lossy (merge Zed's default keymap, resolve contextual +
multi-key bindings, filter Zed frontmost) but doable. If the palette SQLite
data already gathered is "good enough", skip the keylogger entirely.
