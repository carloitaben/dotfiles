---
name: no-tests
description: "Spawn test-sicko, verify its deletions kept coverage and contracts, fix accepted reshape flags."
disable-model-invocation: true
---

# No tests

Spawn Test Sicko. Act on accepted findings.

Authoring agents defend the tests they wrote. Defer to Test Sicko's fresh perspective.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. Record baseline. Run the repo's test and coverage commands on the scope's owners. Save per-file coverage outside `coverage/`. Stop any watch mode first. No coverage tool: skip coverage, say so.
2. Spawn `Task` with `subagent_type: "test-sicko"`. Pass the scope. Do not restate its rules.
3. Inspect its report and diff. Reject application-code edits, scope escapes, replacement tests, deletions missing a named keeper or the failure caught, deletions that match its keep-list, and `MUST KILL` flags that misstate the reason. Restore a deletion only with the exact keep clause and proof. Ambiguous kill: do not restore. Ambiguous keep: delete. Revert and rerun one rejected report with the failure named. Reject a second, report it open, and fail `/no-tests`.
4. Verify. Run owner and sibling tests. Re-measure coverage with the baseline command and compare per production file the deleted tests touched. Where a file lost coverage or the deleted test held the only assertion, mutate the production owner once (flip a condition, drop a call), confirm a keeper goes red, restore byte for byte (`git diff` empty for that file). No red keeper: restore the deleted test and name the contract it guarded.
5. Fix trivial accepted `MUST KILL` flags directly: delete a test-only export, drop an injection parameter, use the real API. If a fix needs a shape, run `/architect` once for the accepted set and surrounding code. Stop at the sketch.
6. Implement the smallest root-cause fix in scope. Remove every named test-only seam. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. Never widen the fence.
7. Unskipped tests that fail are possible product bugs. Report them open with the repro. Do not delete.
8. Report deletion count, restored tests, reruns, coverage delta per file, mutation checks, architect sketch, fixes, unskip results, and other open work. Production lines and test lines counted separately.
