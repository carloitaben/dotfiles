---
name: conflicts
description: Resolve merge conflicts on one or more PRs/branches in parallel worktrees. Args: branch names, PR numbers, PR URLs, any mix.
disable-model-invocation: true
---

Dispatcher. Resolution logic lives in `resolving-merge-conflicts`; stack logic in `gh-stack`. Don't resolve conflicts yourself.

## 1. Parse targets

Each arg, by shape:
- all digits → PR number
- `github.com/<owner>/<repo>/pull/<n>` → PR. Repo must match `origin`; otherwise error.
- else → branch name (PR = its open PR; none → base is the default branch)
- no args → current branch

Resolve each to `{branch, headSha, base, prNumber?}` via `gh pr view --json`.

## 2. Group

A target is in a **stack** if its base isn't the default branch, or another open PR has it as base. Collapse targets in the same stack into one unit. Unit = standalone PR or whole stack.

## 3. Dispatch

One sub-agent per unit, all in parallel (never parallel inside a stack). Each agent gets this contract:

1. `git fetch`, then detached worktree at `$TMPDIR/conflicts/<repo>-<n>` on the head SHA. Never touch the main checkout.
2. Standalone: merge `origin/<base>`. No rebase, no force-push.
   Stack: load `gh-stack`; rebase the whole stack bottom-up with `gh stack`. `git config rerere.enabled true`. Push with force-with-lease only, via `gh stack push`.
3. No conflicts → report `clean`, delete worktree, don't push.
4. Conflicts → load `resolving-merge-conflicts` and follow its **Ask-mode**.
   - Briefings pending → stop mid-merge/rebase, report `needs-input` with briefings and worktree path.
   - All resolved → run the project's typecheck + lint (discover from package.json/CI config, no full tests). Fix breakage the resolution caused; note failures already on base. Commit, push (`git push origin HEAD:<branch>`), delete worktree. Report `pushed` with a one-line-per-hunk list of auto-resolutions.
5. Push rejected (branch moved) → fetch, merge/rebase new head, retry once. New conflicts → new round. Never plain `--force`.
6. Failure (can't push, fork without maintainer edits, checks broken by the merge) → keep worktree, report `failed` with reason and path. Never abort the merge silently.

## 4. Brief

Gather every `needs-input` briefing into one round. Number across targets (`PR#12 Q1`). Use the briefing format from Ask-mode: question, what conflicts, recommended resolution. Wait for answers.

## 5. Resume

Resume each waiting agent (SendMessage) with its answers. It applies them, continues, and may return `needs-input` again (stacks can take several rounds). Repeat 4–5 until every unit is `clean`, `pushed` or `failed`.

## 6. Report

Table, one row per target: PR/branch link, status, auto-resolved count, push result. Failed rows include the kept worktree path.
