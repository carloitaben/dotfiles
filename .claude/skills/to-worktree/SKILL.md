---
name: to-worktree
description: Create a git worktree on a new branch off main, apply a fix there, and open a draft PR. Use when the user asks to fix something in an isolated worktree/branch and open a draft PR, e.g. "create a worktree, branch off main, fix X, open a draft PR".
disable-model-invocation: true
---

# Worktree Fix

Isolate a fix in its own worktree + branch + draft PR, without touching the current working tree.

## Steps

1. **Determine the branch name.** If the user gave a prefix/ticket id (e.g. `JIRA-123`), use it. Otherwise infer the naming convention from the repo itself — don't hardcode a prefix:

   ```
   git branch -a --sort=-committerdate | head -20
   git log --all --oneline -20
   ```

   Mirror whatever pattern recent branches use (prefix like `feature/`, `fix/`, `chore/`, ticket-id casing/format, separators). If the repo has no discernible convention, ask.

2. **Create the worktree** off latest `main` (fetch first if there's a remote):

   ```
   git fetch origin main
   git worktree add ../<dir-name> -b <branch-name> origin/main
   ```

   Pick `<dir-name>` as a sibling directory named after the branch (slashes replaced with `-`).

3. **Apply the fix** inside that worktree directory — all edits, tests, etc. happen there, not in the original working tree.

4. **Commit** the change with a concise message (repo's usual style).

5. **Push and open a draft PR**:

   ```
   git push -u origin <branch-name>
   gh pr create --draft --title "..." --body "..."
   ```

   Follow the repo's usual PR description style if one is known (check for a PR template or prior PR conventions).

6. **Report** the PR URL and the worktree path. Leave the worktree in place — don't remove it or merge the PR without being asked.

## Notes

- Never invent a branch prefix — always check recent branches/log first and mirror what's actually there.
- If `main` isn't the trunk branch name in this repo, use whatever `git remote show origin` / the default branch actually is.
