# Can Karabiner-Elements log actual key presses?

**Research question:** Can Karabiner-Elements record the user's real key presses on macOS so that (cross-referenced against Zed's `keymap.json`) he can reconstruct which Zed commands/keybinds he actually uses — i.e. his muscle-memory keybinds to carry into Neovim?

**Bottom line:** No. Karabiner-Elements has **no key-event logging or export facility** of any kind. Its author has explicitly declined to add one. The practical path is either (a) a custom `complex_modifications` rule that fires `shell_command` per keystroke, or (b) — the maintainer's own recommendation — a standalone `CGEventTap` keylogger. Neither is built-in.

---

## 1. Does Karabiner-Elements record key events to a log file? Can it export/stream them?

**No.**

Karabiner-Elements writes only *error/status* logs, never key events. The documented log locations are:

- `/var/log/karabiner/core_service.log`
- `/var/log/karabiner/virtual_hid_device_service.log`
- `/var/log/karabiner/session_monitor.{uid}.log`
- `~/.local/share/karabiner/log/console_user_server.log`
- `~/.local/share/karabiner/log/core_service.log`

Source: [Show log messages — karabiner-elements.pqrs.org](https://karabiner-elements.pqrs.org/docs/manual/operation/log/) and [File locations](https://karabiner-elements.pqrs.org/docs/json/location/). These contain parse errors, warnings, and `shell_command` stdout — not key events.

The maintainer (tekezo) has **explicitly refused** to add key-event logging:

> "I never add such feature to Karabiner-Elements. You can observe events by yourself." — pointing to `pqrs-org/osx-event-observer-examples`

Source: [Issue #2277 — "Log events to a file?"](https://github.com/pqrs-org/Karabiner-Elements/issues/2277).

### `karabiner_cli` — no key-event capture

The full CLI surface is documented at [Command line interface](https://karabiner-elements.pqrs.org/docs/manual/misc/command-line-interface/) and contains only:

`--select-profile`, `--show-current-profile-name`, `--list-profile-names`, `--list-connected-devices`, `--list-system-variables`, `--list-multitouch-extension-variables`, `--watch-multitouch-extension-variables`, `--set-variables`, `--copy-current-profile-to-system-default-profile`, `--remove-system-default-profile`, `--show-settings-window-guidance`, `--lint-complex-modifications`, `--format-json`, `--eval-js`, `--version`, `--help`.

There is **no** `--watch-keys`, no event stream, no export. A maintainer reply in [Issue #3895](https://github.com/pqrs-org/Karabiner-Elements/issues/3895) confirms the design intent:

> "Basically, there's no way to send key inputs outside of karabiner_grabber … Such approaches could allow other processes to capture keystrokes without permission."

---

## 2. Does the EventViewer export? Can its events be captured programmatically?

**No.**

`Karabiner-EventViewer` is a GUI that displays a live stream of *post-modification* events (what Karabiner emits after rewriting, not the raw hardware key). It has:

- no export/save button,
- no backing file of events,
- a hard cap of ~30 visible events.

Source: [Confirm the result of configuration (EventViewer)](https://karabiner-elements.pqrs.org/docs/manual/operation/eventviewer/). A user asking for a longer buffer and whether events live "in some log on the filesystem" was answered **"Closed as not planned"** — [Issue #4174](https://github.com/pqrs-org/Karabiner-Elements/issues/4174). So there is no supported way to capture EventViewer's stream.

Note: EventViewer shows events *after* modification — e.g. a function key appears as `{"consumer_key_code":"display_brightness_decrement"}` rather than `{"key_code":"f1"}`. Only its "Temporarily turns off all Karabiner-Elements modifications" toggle reveals original events, and only on screen.

---

## 3. Is there a community config/script that "logs every keypress"?

**No widely-used one exists**, but it is *technically possible* to assemble one from three documented primitives:

1. **`from.any: "key_code"`** — matches *all* key events. Source: [from.any](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/any/).
2. **`to.shell_command`** — runs a shell command on match. Source: [to.shell_command](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/shell-command/).
3. **`to.from_event: true`** — re-emits the original key so typing still works. Source: [to.from_event](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/from-event/).

A minimal "log every key and pass it through" rule would look like:

```json
{
  "description": "log every keypress",
  "manipulators": [
    {
      "type": "basic",
      "from": { "any": "key_code", "modifiers": { "optional": ["any"] } },
      "to": [
        { "shell_command": "echo $(date +%s) >> ~/keys.log" },
        { "from_event": true }
      ]
    }
  ]
}
```

**Caveats that make this a poor fit:**

- A shell process is spawned on **every keystroke** (high overhead/latency on a typing path). Karabiner's own docs note `shell_command` runs via `sh` with limited env; there is no synchronous variant, and `shell_command` is async (see [Issue #3157](https://github.com/pqrs-org/Karabiner-Elements/issues/3157)).
- The `shell_command` string itself is static — it does **not** receive the key code as an argument. You cannot easily learn *which* key triggered it from inside the rule (you'd need hundreds of per-key rules, or external `CGEventTap` anyway).
- The maintainer explicitly warns against keylogger-style rules ([Issue #3895](https://github.com/pqrs-org/Karabiner-Elements/issues/3895)).
- `shell_command` output is only logged on non-zero exit ([NEWS.md](https://github.com/pqrs-org/karabiner-elements/blob/main/NEWS.md)), so `echo`-to-file from the rule is the only persistence route.

### The maintainer's recommended route: write your own `CGEventTap` observer

`pqrs-org/osx-event-observer-examples` ([repo](https://github.com/pqrs-org/osx-event-observer-examples)) provides runnable samples of every macOS event-observation API, including **`cgeventtap-example`** (`CGEventTapCreate`) which is exactly what a key logger needs. Requires Accessibility + Input Monitoring permission.

Ready-made community keyloggers (CGEventTap-based) that log to a file/CSV:

- [caseyscarborough/keylogger](https://github.com/caseyscarborough/keylogger) — logs to `/var/log/keystroke.log`.
- [HCanber/keylogger](https://github.com/HCanber/keylogger) (fork) — adds `[fn]`, space, unknown-keycode handling; `keycounter` variant for pure counts.
- [arthurk/keylogger](https://github.com/arthurk/keylogger) — CSV (`key,mod`) to stdout; written for "analyze which keys are pressed the most".
- [patrickcurrie/macos_keylogger](https://github.com/patrickcurrie/macos_keylogger) — keycode → char mapping, `keystroke.log`.

These produce **keycode + modifier** streams — precisely the data needed to match Zed's `keymap.json`.

---

## 4. Practical tradeoffs: can the log be cross-referenced against Zed's `keymap.json`?

**Feasible, but noisy and lossy. Decide whether the signal justifies the effort.**

### What works

- Zed's `keymap.json` binds **key chords** (e.g. `"cmd-shift-p"`, `"g c c"`, `"cmd-p"`) to command names (e.g. `"workspace::ToggleLeftDock"`). A keycode + modifier log can be normalized into the same chord syntax and reverse-mapped.
- Since Zed *only* records palette invocations (SQLite `command_invocations`), a key-event log is the **only** source that captures keybind-run commands — which is exactly the muscle-memory gap the user is trying to fill.

### What's hard / lossy

1. **Frontmost-app filtering.** A raw `CGEventTap` sees *every* app. You must separately track the frontmost app (e.g. `NSWorkspace.shared.frontmostApplication`) or filter the log to Zed sessions, otherwise you get terminal, browser, etc. noise.
2. **Raw keys ≠ commands.** You capture key chords, not Zed's resolved command. Reversing requires merging Zed's *default* keymap with the user's `keymap.json` (defaults live in Zed source `assets/keymaps/*.json` / `assets/settings/*.json`, not the user file), and accounting for:
   - **Contextual bindings** — Zed scopes bindings by mode (Normal/Insert/Visual in Vim mode) and by surface (Editor, Terminal, Project Panel). The same chord maps to different commands in different contexts.
   - **Multi-key sequences** (Vim `g c c` style) — need stateful chord assembly, not just per-key events.
   - **Vim-mode vs default bindings** overlap.
3. **Keycode→symbol mapping.** Keycodes are layout-dependent; a `CGEventKeyboardGetUnicodeString` call (as in the gist examples) yields the typed *character*, but modifiers/combo chords need flag handling (the keyloggers above already implement `convertKeyCode`).
4. **Scope.** Karabiner itself may be rewriting keys *before* Zed sees them — so log at the raw-HID/CGEventTap level (before Karabiner's virtual device) to see what his fingers actually do, or at session level to see what Zed receives. The two differ.

### Worth it vs. palette SQLite alone?

- **Palette data (SQLite `command_invocations`)**: exact command names, zero mapping work, but **blind to keybind-run commands**. Good for "which commands do I even use," useless for "which finger chords are my muscle memory."
- **Key-event log**: captures the chords, but requires the reverse-mapping pipeline above, with contextual-ambiguity error. It is the *only* way to answer the actual question.

**Recommendation:** run a **short, time-boxed capture** (a day or a week of real work) using a `CGEventTap` keylogger filtered to Zed, then map chords→commands via Zed's keymap. That yields the muscle-memory list without building a permanent logger. A permanent, always-on logger is overkill and a privacy risk (it captures passwords unless you stop it for secure fields, as every keylogger README warns).

### Concrete alternative to consider

Zed ships a **built-in** view for this that sidesteps external logging: the Command Palette and the `keymap.json` itself are the *declarative* source; for *usage*, check whether Zed's telemetry/`zed: open log` (or the `~/.local/share/zed` / `~/Library/Application Support/Zed` logs) exposes keybinding-hit telemetry before investing in a keylogger. (Not verified against primary Zed sources here — flagged for follow-up, not asserted.)

---

## Source list

- Karabiner-Elements "Show log messages": https://karabiner-elements.pqrs.org/docs/manual/operation/log/
- Karabiner-Elements "File locations": https://karabiner-elements.pqrs.org/docs/json/location/
- Karabiner-Elements "Command line interface": https://karabiner-elements.pqrs.org/docs/manual/misc/command-line-interface/
- Karabiner-Elements "EventViewer": https://karabiner-elements.pqrs.org/docs/manual/operation/eventviewer/
- Issue #2277 "Log events to a file?" (maintainer decline): https://github.com/pqrs-org/Karabiner-Elements/issues/2277
- Issue #4174 "extend amount of logged events in EventViewer" (closed, not planned): https://github.com/pqrs-org/Karabiner-Elements/issues/4174
- Issue #3895 "access the last key pressed" (maintainer on keystroke capture): https://github.com/pqrs-org/Karabiner-Elements/issues/3895
- Issue #3157 "Buffer input until shell command completes" (shell_command async): https://github.com/pqrs-org/Karabiner-Elements/issues/3157
- `from.any`: https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/any/
- `to.shell_command`: https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/shell-command/
- `to.from_event`: https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/from-event/
- pqrs-org/osx-event-observer-examples (CGEventTap example): https://github.com/pqrs-org/osx-event-observer-examples
- caseyscarborough/keylogger: https://github.com/caseyscarborough/keylogger
- HCanber/keylogger: https://github.com/HCanber/keylogger
- arthurk/keylogger: https://github.com/arthurk/keylogger
- patrickcurrie/macos_keylogger: https://github.com/patrickcurrie/macos_keylogger
