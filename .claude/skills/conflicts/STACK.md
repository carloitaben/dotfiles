# Stack unit

Chained PRs, rebased bottom-up with `gh-stack`. Same report as [AGENT.md](AGENT.md).

1. **Verify**: load `gh-stack`. It must operate without switching or rewriting a branch checked out in another worktree and without disturbing pre-existing work; otherwise report that blocker and `failed`. Done when `gh-stack` is confirmed safe for every branch.
2. **Prepare**: give each branch a worktree: its existing one if clean and idle, else a temporary one on the branch itself (not detached), created at the fetched head. Local HEAD must equal the PR head; on mismatch report both SHAs and `failed`.
3. **Resolve**: one branch at a time, bottom-up, with `-c rerere.enabled=true` so shared config stays untouched. Hunks, lockfiles and checks follow steps 2-4 of AGENT.md. Done when the whole stack rebased cleanly.
4. **Push**: `gh stack push` (force-with-lease). A push can partly succeed: report each branch's result in `note`. Rejected: fetch, reconcile keeping both sides, retry once.
5. **Clean up**: `git worktree remove` for clean temporary worktrees you created that hold no unpushed work. Existing worktrees stay.
