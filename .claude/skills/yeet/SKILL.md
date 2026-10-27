---
name: yeet
description: Oneshot draft PR in an isolated worktree.
disable-model-invocation: true
---

Dispatcher. Stack logic lives in `gh-stack`. Don't implement in the main checkout.

## 1. Brief

Build a self-contained task from args + conversation. The agent sees no chat. Include:
- goal
- decisions already made (e.g. "Q2 → b, not a")
- relevant file paths
- out of scope (main feature, deferred work)

Base: default branch, unless `--base <branch>` → stacked (load `gh-stack`).

Echo one line, don't wait: `dispatching: <goal>, base <base>`.

## 2. Dispatch

- Mid-conversation: one background sub-agent. Main session keeps working.
- Fresh session (task is the whole session): skip sub-agent, run the contract inline via `EnterWorktree`.

## 3. Contract

1. `git fetch`, then new worktree + branch off `origin/<base>`. Never touch the main checkout.
2. Minimal change for the goal only. Run project typecheck + lint (discover from package.json/CI config, no full tests). Fix breakage you caused.
3. Commit, `git push -u origin HEAD`.
4. `gh pr create --draft --base <base> --body-file <tmp>`. Body quoted-heredoc, barebone: short WHY prose, then `## Decisions` for any call made without asking. No diff recap.
5. No mid-flight questions. Make the call, record it under Decisions.
6. Failure (push rejected, checks broken, can't resolve) → keep worktree, report `failed` with reason and path. Never plain `--force`.
7. Success → delete worktree. Report `{url, branch, status}`.

## 4. Report

One line in the main session: PR link. Failed → reason + kept worktree path.
