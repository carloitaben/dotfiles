---
name: shots
description: Take before/after screenshots of a UI change and file them under this session.
disable-model-invocation: true
---

Capture before/after screenshots that prove a UI change, and store them under this session. `/pr-shots` later uploads them.

## Store

`~/.claude/shots/$CLAUDE_CODE_SESSION_ID/`: `manifest.json` plus `<name>/before.png` and `<name>/after.png`. The session has shots when `manifest.json` exists.

Entry shape, written by `shoot.py`:

```json
{"name": "text-block", "url": "…", "selector": "…", "viewport": "1280x800",
 "before": "<abs path>", "after": "<abs path>", "head_sha": "<HEAD at the after shot>", "note": ""}
```

## 1. Choose shots

First match wins:

1. What the user asked to shoot.
2. The PR description, if one exists.
3. The session context: pages and states the change touched.

Each shot is one component or page state (URL, selector, viewport, data), shot twice. Sharp over many: only what the change visibly alters, plus one component it should not alter.

When the change touches many components, render them on a throwaway untracked page with one fixture each and one `data-*` hook per component. Leave the page uncommitted.

## 2. Capture

Load `agent-browser`. Dev server must be running.

**After** first, on the working tree:

```
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py after <name> <url> <selector> [--viewport 1280x800] [--note "…"]
```

**Before** next, on the base branch's files:

```
~/.dotfiles/.claude/skills/shots/base.sh on <base-ref>
# wait for the dev server to recompile, then per shot:
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py before <name> <url> <selector> [same flags]
~/.dotfiles/.claude/skills/shots/base.sh off
```

`base.sh` swaps the files the branch modified (committed or not) to the base ref's version, then restores them. Files the branch adds stay in place; if one changes what renders, hide it from the page. `git stash` does nothing once the change is committed.

`shoot.py` hides everything around the target (siblings of the element and its ancestors, so overlays and cookie banners go too), scrolls to the top and takes an element screenshot. Same URL, viewport and data both times.

Done when `base.sh off` has run and `git status` matches the state before step 2.

## 3. Look

Read every image. Each pair differs where the change is and nowhere else.

- Blank, shifted, clipped at the bottom, or showing unrelated UI: retake.
- A difference outside the intended change (spacing, size, layout of a sibling): a finding. Report it to the user, or fix the change and retake.

Done when every `manifest.json` entry has both images, each read, and every unintended difference is reported.
