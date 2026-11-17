---
name: pr-proof
description: Screenshot before/after proof of a change and add it to the PR description as a table.
disable-model-invocation: true
---

Prove a UI change with a before/after screenshot table in the PR description.

## 1. Resolve the PR

PR = the one passed in, else `gh pr view --json url,number,body` for the current branch.

**No PR: stop.** Say the branch has no PR and none was passed; the user opens one first.

## 2. Choose what to proof

First match wins:

1. What the user asked to proof when summoning this skill.
2. The PR description.
3. The session context: pages and states the change touched.

Each proof is one page and state (URL, viewport, data), shot twice. Fewer, sharper proofs: only what the change visibly alters.

## 3. Capture

Load `agent-browser`. Per proof, take **after** (this branch) and **before** (the base branch) with the same URL, viewport and data, into the scratchpad.

- Before = the base branch running. Cheapest faithful route: revert the change in the running dev checkout, or serve a base worktree.
- Patching the live DOM into the old state counts as before only when it reproduces the old code exactly.
- Both shots show the same thing except the change. Unrelated uncommitted UI (other features in the working tree) in either shot: retake without it.
- Look at every screenshot before uploading. Before differs from after where the change is, and nowhere else.

## 4. Upload

```
python3 -I ~/.dotfiles/.claude/skills/pr-proof/upload.py <pr-url> <image>...
```

All images in one call. It prints JSON `{image path: url}` and clears the comment box it used.

It drives the real keyboard and mouse. Tell the user to keep hands off until it returns. Never click Comment or submit anything by other means.

Failure: report the error; the user may need to clear the PR's comment box by hand.

## 5. Update the PR description

Under `## Proof`, one table per proof. Name the proof above the table when there are several. `img` is the markdown image for the URL: `![Before](url)`.

```
|Before|After|
|:-:|:-:|
|img|img|
```

Replace an existing `## Proof` section, else append it. Write the full body to a temp file with a quoted heredoc, then `gh pr edit <pr> --body-file`.

Done when the PR body renders every proof with both images, confirmed by re-reading it via `gh pr view`.
