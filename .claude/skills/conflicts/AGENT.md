# Conflict resolution agent

Resolve the hunks of one unit; `<skill-directory>/scripts/merge.py` does the git and CI mechanics (`--help` per subcommand). End with `clean`, `needs-input`, `pushed`, or `failed`.

A `stack` unit follows [STACK.md](STACK.md) instead of the steps below.

## Standalone unit

One branch, merged with `origin/<base>`.

1. **Prepare**: `merge.py prepare <branch> --base <base> --sha <headSha>`. A failure is a **blocker**: report `failed` with its error and change nothing.
   - `clean`: report `clean`. With `mergedLocally`, the merge commit is unpushed; retain the worktree and say so.
   - `conflicted`: continue.
2. **Resolve**: load `resolving-merge-conflicts` and follow **Ask-mode** for the listed files. Pending briefings leave the merge in progress; report `needs-input` with every briefing, auto-resolution, and the worktree path. Resume with the answers. Done when no file is unmerged.
3. **Lockfile**: resolve manifests first, then `merge.py lockfile <worktree>`. Churn in `addedLines`/`removedLines` beyond the branch's own dependency changes earns a closer look.
4. **Check**: `merge.py check <worktree>` typechecks and lints each changed package. Fix breakage the resolution caused, including leftovers from the base's renames and moves. Failures already on the base stay; note them. Done when `status` is `ok`, `no-checks`, or every failure is noted as pre-existing.
5. **Finish**: `merge.py finish <worktree>`. Done when it prints `pushed`.
   - `rejected`: fetch, reconcile the new head keeping both sides, rerun `finish` once. When that is unsafe, report `failed`; new conflicts start another briefing round.

## Report

End with one JSON object:

```json
{"pr": 12, "url": "https://github.com/o/r/pull/12", "branch": "feature/x", "status": "pushed",
 "resolved": ["path/to/file.ts: kept branch's import, took base's path"],
 "push": "abc1234..def5678", "worktrees": [], "note": ""}
```

`resolved` has one line per auto-resolved hunk. `worktrees` lists every retained path: all of them on `failed` or `needs-input`, and every pre-existing one. Leave worktrees and half-finished merges exactly as found, so the user can inspect them.
