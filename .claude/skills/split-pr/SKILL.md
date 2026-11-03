---
name: split-pr
description: Interactively split changes into multiple smaller draft PRs.
disable-model-invocation: true
---

Split the diff between the current branch and its target into independent (or stacked) branches + draft PRs. Everything before the step 5 gate is local and reversible: never push or touch GitHub earlier.

## 1. Determine base

- Base = branch this one will merge into: the upstream's remote HEAD, or the default branch (`gh repo view --json defaultBranchRef`). Ask if ambiguous.
- `git merge-base <base> HEAD`: everything after is in scope.
- **Pin the final state.** `git update-ref refs/split/snap HEAD`. Every `<original-branch>` below means this ref. If the working tree is dirty, ask whether it is in scope, then commit it to a ref first (`git stash create` returns nothing on a clean tree).
- **Check drift.** Fetch base. Intersect `git diff --name-only <merge-base> <base>` with the branch's files, then test-merge the pinned tip onto the base tip in a scratch worktree and abort. Conflicts: report and stop (slices build on the base tip and would inherit them), offer to rebase the branch first, restart from the new tip. Only generated files (lockfiles, catalogs) conflicting makes the rebase mechanical; say so. Rebase only on the user's say-so.

## 2. Gather signal

- Full `git diff <merge-base>..HEAD`: the final state, source of truth. Group from the diff alone; commit history, messages and boundaries say nothing about feature shape.
- File paths mislead: one package can hold two unrelated features, one feature can span packages.
- Search open PRs already carrying part of the diff: `gh pr list --state open --search "<identifier> in:title,body"` for key new identifiers (props, helpers, error codes). See *Overlap* below.

## 3. Propose groupings

**Neat conceptual slices.** Each PR reads as one idea. Group by final logical ownership; *when* a hunk was introduced or touched never decides its group. A hunk that adds `Foo` and a later one that guts it belong to one `Foo` group, not "introduce Foo" under "simplify Foo".

**Reviewable unit.** A group is one behavior a reviewer judges in one sitting. Budget **200–400 changed LOC** (excluding generated files, snapshots, locale strings); over ~500 or two concepts: split. Under ~100 without standalone value: fold into a neighbor. Fewest PRs under the budget: 5–8 per stack reads as a story; 15+ is notification and merge-chain noise.

- **Vertical.** Slice by behavior, backend and frontend together ("filter text fields", then "add number operators"), so each PR is demoable and the feature reverts cleanly. Split by layer only when the sides ship independently.
- **Spend review on risk.** Isolate what needs real scrutiny (data model, queries, permissions, migrations) in its own PR. Fold mechanical code (helpers, wiring, barrels, locale strings) into the PR that uses it.
- **Tests ship with their feature.** Each PR carries what its description needs: screenshot or video for UI, example request for API.
- **Slice inside a file** when that is the only way under budget: hand-author intermediate states that never existed on the branch (option C in [REFERENCE.md](REFERENCE.md)). An intermediate state needn't be a pure subset of the final diff.

The invariant: the union of all branches reproduces the final tree exactly (step 4).

Cover every changed file/hunk. Anything not obviously part of a feature becomes its own group. Per group note owned files/hunks and dependencies on other groups.

**Standalone value.** Could a reviewer judge the group without its consumer? A new option, error code or helper nothing reads yet is dead code: fold it into its first consumer, or stack it right before. Default to one linear stack.

**Parallel prerequisites.** Only a group that stands alone and merges on its own (behavior-preserving refactor, bug fix) becomes a parallel PR off base. Dependent branches *also keep that hunk, identical to the parallel PR's*, so it drops out of their diff once the parallel PR merges. Only real code dependencies between feature groups become stacking edges.

**Overlap with an open PR.** Don't author your own copy of a hunk another open PR carries. Take the file from that PR's branch (byte-identical) into the first group needing it; note the PR in the plan. If the branch's version differs (comment removed, rename), tell the user which side should change: the second to merge conflicts or reverts.

**Generated files** (catalogs, snapshots, route trees) change in many slices. Ask where they land (each slice or only the last).

**Branch names.** Original `feature/ABC-123-big-feature` gives `feature/ABC-123-<slug>`: keep the ticket prefix, show full names.

Present an ASCII tree: base as root, independent groups as children, dependents nested under their parent (nesting = stacking). Annotate file count and `+added −removed`:

```
main
├── auth-refactor (12 files, +340 −20)
├── api-pagination (5 files, +90 −12)
└── ui-cleanup (8 files, +210 −55)
    └── ui-cleanup-tests (3 files, +120)
```

**Count before presenting.** Any chain over 8 PRs, or any group under ~100 LOC, merge adjacent groups until each earns its PR.

Confirm via `AskUserQuestion`. The user may merge/split groups, reassign files, rename, change edges. Redraw each round until confirmed. No git writes yet.

## 4. Build local branches via gh-stack

Use the [gh-stack](../gh-stack/SKILL.md) skill for all branch creation, switching and stacking; no hand-made `git checkout -b`. Build in a separate worktree (`git worktree add --detach <path> <base>`) so the user's checkout stays untouched.

Stacks are strictly linear. Partition the tree into **chains**: each top-level group plus everything nested under it = one stack rooted at base. Sibling top-level groups are separate stacks.

Per chain, in dependency order:

- First branch: `gh stack init --base <base> <branch-name>`. For a second/later chain, first `gh stack checkout <base>` (or `gh stack trunk` if in a stack) so you don't sit on another stack's branch.
- Later branches: `gh stack add <branch-name>` from the stack's current top.
- Land the group's state per [REFERENCE.md](REFERENCE.md), as one fresh commit. Never cherry-pick original commits.
- **Commit message: short subject, no body, written fresh.** `gh stack submit --auto` makes the PR title/body from commits: a single commit gives title = subject, body = commit body; several commits give a humanized branch name and no body. One bodiless commit = barebones PR (no generated prose, test plan or ticket content). Stack linking already shows "stacked on #N"; add no manual note.

**Verify hand-authored states.** A fresh worktree has no installed deps: copy each hand-authored file into a checkout that has them, typecheck/lint/format-check, restore. Report any state you couldn't check.

**Verify losslessness.** Overlay every new branch tip (parallel branches + top of each chain) onto base in a scratch worktree or via `git read-tree`; `git diff <original-branch> <combined-tree>` must be empty. A difference means a dropped, wrongly duplicated or hand-edited hunk: fix before step 5. Duplicated prerequisite hunks must match byte for byte. Declare any expected difference up front (e.g. a file made identical to another open PR's) and require the diff to equal exactly that.

If a group's diff won't apply cleanly, stop and flag it; never guess a resolution. The original branch stays untouched.

## 5. Single confirmation gate

Show the final tree again. One go/no-go for the whole batch, not per branch.

## 6. Push + draft PRs

Per chain: `gh stack checkout <top-branch>`, then `gh stack submit --auto` (pushes every branch, opens chained draft PRs, links them as a GitHub Stack). Report PR URLs (`gh stack view --json` or `submit` output).
