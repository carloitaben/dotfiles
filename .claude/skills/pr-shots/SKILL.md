---
name: pr-shots
description: Upload this session's before/after screenshots to a PR and add them to its description.
disable-model-invocation: true
---

Put this session's before/after screenshots into the PR description as tables. The screenshots come from `/shots`.

## 1. Resolve the PR

PR = the one passed in, else `gh pr view --json url,number,body` for the current branch.

**No PR: stop.** Say the branch has no PR and none was passed; the user opens one first.

## 2. Get current shots

```
python3 -I ~/.dotfiles/.claude/skills/pr-shots/update-body.py check
```

It fails when this session has no shots, an image is missing, or a shot was taken at an older commit than HEAD. On failure, read and follow `~/.dotfiles/.claude/skills/shots/SKILL.md` for the missing or stale shots (what the user asked to shoot when summoning this skill chooses them), then run `check` again.

Done when `check` passes.

## 3. Upload

```
python3 -I ~/.dotfiles/.claude/skills/pr-shots/update-body.py paths
python3 -I ~/.dotfiles/.claude/skills/pr-shots/upload.py <pr-url> <image>... > <scratchpad>/urls.json
```

All images in one call. It prints JSON `{image path: url}` and clears the comment box it used. It runs in agent-browser's own headless browser, so the user can keep working.

Needs the `gh` agent-browser session signed in to GitHub (profile `~/.agent-browser/profiles/gh`). The script exits at once with the setup command when it is not. One-time setup: run that command, sign in, close the window.

Never click Comment or submit anything by other means.

Failure: report the error; the user may need to clear the PR's comment box by hand.

## 4. Update the PR description

```
python3 -I ~/.dotfiles/.claude/skills/pr-shots/update-body.py write <pr> <scratchpad>/urls.json
```

It replaces the `## Proof` section, else appends it: one before/after table per shot, titled by name and note.

Done when it reports every image in the PR body (exit 0).
