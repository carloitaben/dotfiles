---
name: playthrough
description: Make a captioned mp4 playthrough of a bug repro, a before/after comparison or a stateful flow, from agent-browser screenshots at 1280x720. Use when asked for a playthrough, a repro video, a walkthrough of what happened, "record this", or an mp4 of the steps for a PR. For a polished scripted demo with a cursor, use webreel.
disable-model-invocation: true
---

# Playthrough

A playthrough is one screenshot per beat, each with a caption, joined into an mp4. Prefer it to `agent-browser record`: recording reloads or re-creates the page, which wiped in-memory state and hid a cache bug that reproduced every time without it. Screenshots leave the app as it behaves normally.

## Steps

1. Dry-run the flow first, without capturing. Confirm it does what you will claim, on every variant (for example `main` and the fix). Never caption a result you did not read from the page.
2. Reset any data the flow changes so every variant starts equal, and restore it after.
3. Write one bash script per variant (not zsh: it does not word-split). Source `scripts/lib.sh` for `ab`, `caption` and `shot`.
4. One beat per user-visible step: `caption "what happens"`, then `shot <seconds>`. Read the real outcome from the DOM and put it in the last caption with a ✓ or ✗.
5. Run each variant into its own frames dir, then `scripts/frames-to-mp4.sh out.mp4 <dir> [<dir>...]`. Several dirs make a before/after reel.
6. Check a frame or two by eye, then put the mp4 somewhere durable (not `/tmp`) and `open -R` it. Report only runs you actually did.

## agent-browser notes

- `agent-browser set viewport 1280 720`, once per tab. A new tab starts at the default size.
- Tabs are `t1`, `t2`, ...: `tab new <url>`, `tab t2`, `tab close t2`. Positional numbers are rejected, and a failed switch silently acts on the current tab, so list tabs after creating one.
- Two tabs in one session share storage, so cross-tab behavior (BroadcastChannel, localStorage) is real.
- A different origin or port needs its own auth: copy the token into that origin's `localStorage`.
- Several app versions side by side: a git worktree per version, symlink `node_modules` and `.env`, each dev server on its own port. Kill only your own PIDs and remove the worktrees afterwards.
- Triggering in-app navigation: click the real link with `eval`, or `history.back()`. A full `open` resets in-memory caches, which is often exactly what you must avoid.
