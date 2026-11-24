---
name: simplify
description: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.
---

`/simplify → cleanup agents (1 or 4, by diff size) → apply the fixes`

Improve the quality of the changed code, not hunt for bugs. Review it for reuse,
simplification, efficiency, and altitude issues, then fix what you find. Do not
look for correctness bugs — that is what `/code-review` is for.

## Phase 0 — Gather the diff

Run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` / `git diff HEAD~1`
if there's no upstream) to get the unified diff under review. If there are
uncommitted changes, or the range diff is empty, also run `git diff HEAD` and
include the working-tree changes in scope — the review often runs before the
commit. If a PR number, branch name, or file path was passed as an argument,
review that target instead. Treat this diff as the review scope.

Write the diff to a file in the scratchpad (run `git add -N` on untracked files
first so new files appear in it) and count its changed lines. Agents read the
diff from that path.

## Phase 1 — Review in fresh context

The review always runs in subagents: a **fresh context** reads the diff
unanchored by the reasoning that wrote it. Size the dispatch to the diff:

- **Under ~80 changed lines:** launch **1 review agent** with all four angles
  below in its brief.
- **Otherwise:** launch **4 review agents** in a single message so they run
  concurrently, one angle each.

Pass each agent the diff path and its angle(s). Each returns its findings with
`file`, `line`, a one-line `summary`, and the concrete cost (what is
duplicated, wasted, or harder to maintain).

### Reuse

Flag new code that re-implements something the codebase already has — Grep
shared/utility modules and files adjacent to the change, and name the existing
helper to call instead.

### Simplification

Flag unnecessary complexity the diff adds: redundant or derivable state,
copy-paste with slight variation, deep nesting, dead code left behind. Name the
simpler form that does the same job.

### Efficiency

Flag wasted work the diff introduces: redundant computation or repeated I/O,
independent operations run sequentially, blocking work added to startup or hot
paths. Also flag long-lived objects built from closures or captured
environments — they keep the entire enclosing scope alive for the object's
lifetime (a memory leak when that scope holds large values); prefer a
class/struct that copies only the fields it needs. Name the cheaper
alternative.

### Altitude

Check that each change fixes the root cause at the right depth rather than
patching a symptom with a fragile bandaid. Special cases layered on shared
infrastructure are a sign the fix isn't deep enough — prefer the simpler, more
general change to the underlying mechanism over adding special cases, and name
that change.

## Phase 2 — Apply the fixes

Wait for every review agent to complete, dedup findings that point at the same line
or mechanism, and fix each remaining one directly. Skip any finding whose fix
would change intended behavior, require changes well outside the reviewed diff,
or that you judge to be a false positive — note the skip rather than arguing
with it. Finish with a brief summary of what was fixed and what was skipped (or
confirm the code was already clean).
