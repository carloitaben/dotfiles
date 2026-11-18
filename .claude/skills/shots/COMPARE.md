# Comparison mode

Capture before/after screenshots that prove a UI change. Replaces steps 2 and 3 of [SKILL.md](SKILL.md); step 1 (Choose shots) stays.

Each shot is one component or page state (URL, selector, viewport, data), shot twice. Sharp over many: only what the change visibly alters, plus one component it should not alter.

## Store

`<name>/before.png` and `<name>/after.png` instead of `shot.png`. Entry shape, written by `shoot.py`:

```json
{"name": "text-block", "kind": "comparison", "url": "…", "selector": "…", "viewport": "1280x800",
 "before": "<abs path>", "after": "<abs path>", "head_sha": "<HEAD at the after shot>", "note": ""}
```

## Capture

Load `agent-browser`. Dev server must be running.

**After** first, on the working tree:

```
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py after <name> <url> <selector> [--viewport 1280x800] [--note "…"]
```

**Before** next, on the base branch's files:

```
~/.dotfiles/.claude/skills/shots/base.sh on "$(git merge-base HEAD origin/<parent>)"
# wait for the dev server to recompile, then per shot:
python3 -I ~/.dotfiles/.claude/skills/shots/shoot.py before <name> <url> <selector> [same flags]
~/.dotfiles/.claude/skills/shots/base.sh off
```

`<parent>` = the PR's base (`gh pr view --json baseRefName`), else the branch this one was cut from, else `develop`. `main` is too far for a long-lived branch: it differs by hundreds of files and breaks the app. `base.sh on` reports a small file count; a large one means the wrong ref.

`base.sh` swaps the files the branch modified (committed or not) to the base ref's version, then restores them. Files the branch adds stay in place; if one changes what renders, hide it from the page. `git stash` does nothing once the change is committed.

Same URL, viewport and data both times.

After `base.sh off`, the dev server can keep serving stale transforms of swapped files (check by curling a swapped module). Touching the file may not clear it; restart the dev server as a last resort.

Done when `base.sh off` has run and `git status` matches the state before capture.

## Look

Read every image. Each pair differs where the change is and nowhere else.

- Blank, shifted, clipped at the bottom, or showing unrelated UI: retake.
- A difference outside the intended change (spacing, size, layout of a sibling): a finding. Report it to the user, or fix the change and retake.

Done when every `manifest.json` entry has both images, each read, and every unintended difference is reported.
