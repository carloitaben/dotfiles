---
name: shots
description: Screenshot pages or components, or record loading sequences as video, and file them under this session. Before/after comparison on request.
disable-model-invocation: true
---

Screenshot the UI the user named and file it under this session. `/pr-shots` later uploads it.

**Video**: when the point is a sequence in time (loading states, spinner order, a transition) and not one moment, read [VIDEO.md](VIDEO.md) and follow it in place of steps 3 and 4. A video comparison reads [COMPARE.md](COMPARE.md) for the base-files swap too.

**Comparison**: when the user asks for before/after, to screenshot the changes, or to compare with a baseline, read [COMPARE.md](COMPARE.md) and follow it in place of steps 3 and 4. Every other request is a single shot per page or component.

## Store

`~/.claude/shots/$CLAUDE_CODE_SESSION_ID/`: `manifest.json` plus `<name>/shot.png`. The session has shots when `manifest.json` exists.

Entry shape, written by `shoot.py` (`clip.py` writes `"kind": "video"` with `video`, or `"video-comparison"` with `before` and `after`):

```json
{"name": "text-block", "kind": "shot", "url": "…", "scope": "element", "device": "desktop",
 "selector": "…", "viewport": "1512x982@2", "image": "<abs path>",
 "head_sha": "<HEAD at the shot>", "note": ""}
```

One store per PR when a session shoots several: run `shoot.py` and `/pr-shots` with `CLAUDE_CODE_SESSION_ID=pr-<number>`, on that PR's branch (`head_sha` must equal the branch's HEAD).

## 1. Choose shots

First match wins:

1. What the user asked to shoot.
2. The PR description, if one exists.
3. The session context: pages and states the change touched.

Each shot is one page state or one component: URL, scope, device, data.

**Scope** decides what the image frames. Pick it in this order:

1. The user's words. "The page", "the screen", "on mobile": `page`. A named component: `element`.
2. The diff. Layout, navigation, routes, headers, responsive CSS or a page's empty and error states: `page`. One component's internals: `element`.
3. Neither settles it: ask in step 2.

- `page`: the viewport as the user sees it, app chrome included. The change shows in its surroundings.
- `element`: one component, cropped to its content and padded. The page around it adds noise. The selector names the subject; `shoot.py` shoots the subject's first ancestor that does not sit flush with it, so the image carries the heading, neighbours or padding around it. `--bare` shoots the subject alone. `--pad N` changes the 24px margin and `--pad 0` leaves a tight crop.

**Device** decides the frame size:

- `desktop`: MacBook Pro 14", 1512×982 at 2×. The default.
- `mobile`: iPhone 16 Pro, 402×874 at 3×, touch and mobile user agent.

A responsive change gets both: one shot per device, named `<name>-desktop` and `<name>-mobile`. Anything else gets the device the user named, else `desktop`.

A page shot is the viewport, what shows on load. `--zoom 0.8` fits more into the frame when the subject runs past the fold. `--full` captures the whole page length when the length is the point.

When shots span many components, render them on a throwaway untracked page with one fixture each and one `data-*` hook per component. Leave the page uncommitted.

## 2. Confirm

Everything before this gate is local and reversible: capture nothing earlier.

Send the plan alone as a chat message (an `AskUserQuestion` dialog in the same turn covers it), one row per image:

```
shot                  url              scope    device   note
leads-report-desktop  /leads/report    page     desktop  tab bar and sidebar, Report selected
leads-report-mobile   /leads/report    page     mobile   same page, narrow
tab-bar               /leads/report    element  desktop  the tab bar alone, indicator on Report
```

Then ask in plain text whether to go ahead. One go/no-go for the whole batch. Changing a scope, device, URL, or adding or dropping a shot redraws the table; repeat until the user confirms.

## 3. Capture

Load `agent-browser`. Dev server must be running. Run from the repo root.

An app behind a login: set `AGENT_BROWSER_SESSION` and `AGENT_BROWSER_RESTORE` to the signed-in session's name first, so `shoot.py` opens pages as that user.

```
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py shot <name> <url> --scope page [--device desktop|mobile] [--zoom 0.8] [--full] [--note "…"]
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py shot <name> <url> <selector> --scope element [--device desktop|mobile] [--bare] [--pad N] [--note "…"]
```

`shoot.py` has no click steps: put the state in the URL (search params, `#hash`), so the fresh browser lands on it. A `#<id>` hash selects and expands that node in tree views.

`shoot.py` opens a fresh browser at the device size, reads the size back and fails when it did not apply. A page shot takes the viewport. An element shot hides everything around the target (siblings of the target and its ancestors, so overlays and cookie banners go too), scrolls to the top and takes an element screenshot.

**Preview first.** Capture one shot of the batch, read it, and reveal it with `open -R <image>` when the user wants to see it. The rest of the batch runs once that shot frames its subject: the subject's size sets the image's size, and an image far larger than its subject has the wrong ancestor (retake with `--bare`).

Done when every confirmed shot has an entry in `manifest.json`.

## 4. Look

Read every image.

- Blank, shifted, clipped at the bottom, or showing unrelated UI: retake.
- A page shot without the app chrome, or an element shot that still carries it: the scope is wrong; retake with the other.
- Not what the shot was meant to show (wrong state, missing styles): fix the page or the selector, then retake.
- A viewer cannot tell what the component is or what it sits in: select a subject deeper inside a larger block, or wrap it in a labelled container on the page, then retake.

Done when every `manifest.json` entry has its image, each one read and showing its subject.
