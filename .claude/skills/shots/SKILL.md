---
name: shots
description: Screenshot components or pages and file them under this session. Before/after comparison on request.
disable-model-invocation: true
---

Screenshot the UI the user named and file it under this session. `/pr-shots` later uploads it.

**Comparison**: when the user asks for before/after, to screenshot the changes, or to compare with a baseline, read [COMPARE.md](COMPARE.md) and follow it in place of steps 2 and 3. Every other request is a single shot per component.

## Store

`~/.claude/shots/$CLAUDE_CODE_SESSION_ID/`: `manifest.json` plus `<name>/shot.png`. The session has shots when `manifest.json` exists.

Entry shape, written by `shoot.py`:

```json
{"name": "text-block", "kind": "shot", "url": "…", "selector": "…", "viewport": "1280x800",
 "image": "<abs path>", "head_sha": "<HEAD at the shot>", "note": ""}
```

## 1. Choose shots

First match wins:

1. What the user asked to shoot.
2. The PR description, if one exists.
3. The session context: pages and states the change touched.

Each shot is one component or page state (URL, selector, viewport, data). The selector names the subject; `shoot.py` shoots the subject's first ancestor that does not sit flush with it, so the image carries the heading, neighbours or padding around it. `--bare` shoots the subject alone. The target is cropped to its visible content and padded with 24px of the page's background on every side, so no edge is flush and no empty space trails it; `--pad N` changes the margin and `--pad 0` leaves a tight crop.

When the shots span many components, render them on a throwaway untracked page with one fixture each and one `data-*` hook per component. Leave the page uncommitted.

## 2. Capture

Load `agent-browser`. Dev server must be running.

```
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py shot <name> <url> <selector> [--viewport 1280x800] [--note "…"]
```

`shoot.py` hides everything around the target (siblings of the target and its ancestors, so overlays and cookie banners go too), scrolls to the top and takes an element screenshot.

Done when every chosen shot has an entry in `manifest.json`.

## 3. Look

Read every image.

- Blank, shifted, clipped at the bottom, or showing unrelated UI: retake.
- Not what the shot was meant to show (wrong state, missing styles): fix the page or the selector, then retake.
- A viewer cannot tell what the component is or what it sits in: select a subject deeper inside a larger block, or wrap it in a labelled container on the page, then retake.

Done when every `manifest.json` entry has its image, each one read and showing its subject.
