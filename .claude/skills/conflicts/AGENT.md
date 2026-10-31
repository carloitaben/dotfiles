# Conflict resolution agent

Handle the assigned unit; process stack branches serially, bottom-up. Report `clean`, `needs-input`, `pushed`, or `failed` to the dispatcher, with per-branch push results and retained worktree paths.

## Prepare worktrees

Fetch `origin`, then inventory every affected local ref and worktree with `git worktree list --porcelain`. For each branch:

- If checked out, use its **existing** worktree, including the main checkout. Proceed only if it is clean, has no operation in progress, and is not in use; if uncertain, fail without changing it.
- Otherwise create a unique **temporary** worktree with the branch checked out, not detached. If the local branch doesn't exist, create it at the fetched head. Preserve existing local refs: verify local HEAD matches the fetched PR head; on mismatch fail and report both SHAs, rather than resetting it.

Before changing a stack, verify that `gh-stack` can operate without switching or rewriting a branch checked out in another worktree or disturbing pre-existing work. If not, report the blocker and fail; keep each branch in its assigned worktree.

## Resolve

- **Standalone:** merge `origin/<base>` into the branch; no rebase or force-push.
- **Stack:** load `gh-stack`, verify it can handle the unit, and rebase bottom-up. Configure rerere without unexpectedly changing shared repository configuration. Push only via `gh stack push` with force-with-lease.

If no conflicts occurred, report `clean` without pushing. A completed operation may have produced unpushed local history; report it and retain the worktree.

For conflicts, load `resolving-merge-conflicts` and follow **Ask-mode**. While briefings are pending, leave the operation in progress and report `needs-input`, all briefings, auto-resolutions, and the worktree path. When answers arrive, continue; repeat if more questions arise.

Once resolved, run the project's typecheck and lint, discovered from project configuration; no full tests. Fix breakage caused by the resolution and note failures already on base. Complete the merge/rebase and push: standalone `git push origin HEAD:<branch>`; stack `gh stack push`. Report `pushed` with one line per auto-resolved hunk.

If a push is rejected, fetch and reconcile the new head without discarding either side, then retry once. If unsafe, fail; new conflicts start another briefing round. Stack pushes can partially succeed: report each branch's result. Never use plain `--force`.

## Cleanup

Always retain existing worktrees. After a successful push or a `clean` result, remove only clean temporary worktrees created by this run that contain no unpushed work, using `git worktree remove`. On failure or pending input, retain all worktrees. Report every retained path. Never force-remove a worktree, discard a merge for cleanup, or silently abort an operation.
