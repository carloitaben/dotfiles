---
name: split-pr
description: Interactively split a changes into multiple smaller draft PRs.
disable-model-invocation: true
---

Split the diff between the current branch and its target into multiple independent (or stacked) branches + draft PRs. Never push or open a PR without the single confirmation in step 5. Everything before that is local and reversible.

## 1. Determine base

- Base = the branch this one will eventually merge into. Try `git rev-parse --abbrev-ref --symbolic-full-name @{u}`'s remote HEAD, or the repo's default branch (`gh repo view --json defaultBranchRef`). Ask the user if ambiguous.
- Compute `git merge-base <base> HEAD`. Everything after this commit is in scope.
- **Pin the final state.** Slice from a fixed ref, not the moving branch: `git update-ref refs/split/snap HEAD` (if the working tree is dirty, ask whether it is in scope, then commit it to a ref first; `git stash create` returns nothing on a clean tree). Every `<original-branch>` below means this ref.
- **Check drift against the base.** Fetch the base. List files changed on both sides (`git diff --name-only <merge-base> <base>` intersected with the branch's files), then test-merge the pinned tip onto the base tip in a scratch worktree and abort. Report any conflicts and stop: slices are built on the base tip, so they would inherit them. Offer to rebase the branch first, then restart from the new tip. If only generated files conflict (lockfiles, catalogs), say so; that makes the rebase mechanical.

## Principle: neat conceptual slices beat pure diff slices

The goal is PRs a reviewer can read as one idea each. Slicing the final diff mechanically is not the goal. To get a neat slice you may need to **hand-author intermediate file states** that never existed on the original branch, e.g. a shared component without the code for features that land in later groups. That is expected and fine. Do not collapse groups together just because the intermediate state isn't a pure subset of the final diff. The invariant that matters: the union of all branches reproduces the original branch's final tree exactly (verified in step 4).

## 2. Gather signal

- Full `git diff <merge-base>..HEAD` for content. This is the source of truth for the final state. Read the final-state diff, not the commit history.
- Don't consult `git log`, commit messages, or commit boundaries for grouping. Commits don't tell you anything about feature shape. Group from the diff alone.
- Don't rely on file paths alone. A single package can contain two unrelated features, and one feature can span packages.
- Check for open PRs that already carry part of the diff: search with `gh pr list --state open --search "<identifier> in:title,body"` for the key new identifiers (props, helpers, error codes). A hunk that already lives in another PR is handled as in "Overlap with an open PR" below.

## 3. Propose groupings

Group by final logical ownership, not chronology. Ignore commit boundaries and messages entirely. Never let *when* a file/hunk was introduced or last touched decide its group. If an early hunk adds `Foo` and a later one guts it because infra built in between made that possible, it's still one group (`Foo`, final state), not an "introduce Foo" PR stacked under a later "simplify Foo" PR. Reviewers read the diff, not the commit history; the split should reflect the shape of the final diff only.

Prefer many small, single-concept groups (one feature, one layer) over a few large ones. A feature's tests ship in the same PR as the feature; never split tests into their own PR. When the user asks for the smallest PRs possible, slice by feature even inside one file or component, writing intermediate states by hand where needed.

Propose named feature groups covering every changed file/hunk. No leftovers: anything not obviously part of a feature becomes its own group, never silently dropped. For each group note which files/hunks it owns, and whether it depends on another group's code being present.

**Standalone value test.** Before making any group its own PR, ask: could a reviewer judge it without seeing its consumer? A new option, error code or helper that nothing reads yet is dead code on its own. Fold it into the first group that uses it, or keep it as a stack member right before its consumer so the reader meets it in order. Default to one linear stack.

**Parallel prerequisites (only when independently valuable).** Make a group a *parallel* PR off base only if it stands alone and is mergeable on its own, e.g. a behavior-preserving refactor or a bug fix. The dependent branches **also keep that same hunk, identical to the parallel PR's version**. Once the parallel PR merges, the dependent PRs no longer show that hunk in their diff, because the code is the same on both sides. Only real code dependencies between feature groups become stacking edges (nesting).

**Overlap with an open PR.** If another open PR already carries a hunk the diff needs, do not author your own copy. Take that file from the other PR's branch so it is byte-identical, keep it in the first group that needs it, and note the PR in the plan. The hunk then drops out of your diff when that PR merges. If the branch's version of the file differs from the other PR's (a comment removed, a rename), tell the user which side should change, since whichever merges second will conflict or revert.

**Generated files.** Files regenerated from source (catalogs, snapshots, route trees) change in many slices at once. Ask the user where they should land (each slice, or only the last) before building.

**Branch names.** Prefix every branch with the original branch's ticket prefix, e.g. original `feature/ABC-123-big-feature` gives `feature/ABC-123-<slug>`. Show the full prefixed names in the tree.

Present the plan as an ASCII tree — base branch as root, independent groups as its children, dependent groups nested under their parent group (nesting = stacking order). Annotate each node with file count and `+added −removed` lines, so size is visible. Example:

```
main
├── auth-refactor (12 files, +340 −20)
├── api-pagination (5 files, +90 −12)
└── ui-cleanup (8 files, +210 −55)
    └── ui-cleanup-tests (3 files, +120)
```

Show this tree, ask for confirmation via AskUserQuestion and iterate: let the user merge/split groups, reassign files, rename branches, or change dependency edges — redraw the tree each round. Loop until confirmed. **No git writes yet.**

## 4. Build local branches via gh-stack

Use the [gh-stack](../gh-stack/SKILL.md) skill for all branch creation, switching, and stacking. Never `git checkout -b` these branches by hand.

Build in a separate worktree (`git worktree add --detach <path> <base>`) so the user's checkout is untouched. `gh stack` works there.

gh-stack stacks are strictly linear (one parent, one child per branch). So first partition the step-3 tree into **chains**: each independent (top-level) group plus everything nested under it is one chain = one stack rooted at base. Sibling top-level groups become *separate* stacks, not branches of the same stack.

For each chain, in dependency order:

- First branch in the chain: `gh stack init --base <base> <branch-name>` (creates the stack, branches off base, checks it out). If starting a second/third chain, first `gh stack checkout <base>` (or `gh stack trunk` if already in a stack) so you're not sitting on a branch shared by another stack.
- Each subsequent (dependent) branch in the same chain: `gh stack add <branch-name>` (must be run from the current top of that stack).
- Once the branch is created and checked out, isolate that group's changes onto it. See [REFERENCE.md](REFERENCE.md) for the per-file vs. per-hunk mechanics — pick the simplest one that fits the group. Never cherry-pick original commits: always land the group's state as one fresh commit, regardless of how many original commits it came from. When the group is a conceptual slice rather than a pure diff slice, hand-edit the files into the intended intermediate state (see REFERENCE.md, option C).
- `git add` the isolated files and `git commit` with a short message derived from the group's feature summary (subject line only — see the PR body note in [REFERENCE.md](REFERENCE.md)). Write this message fresh; don't reuse or adapt an original commit message.

**Verify hand-authored states.** A fresh worktree usually has no installed dependencies. To typecheck, lint and format-check a hand-authored intermediate file, copy it into a checkout that has them, run the checks, then restore the file. Report any state you could not check.

**Verify losslessness before step 5.** Merge/overlay every new branch tip onto base (parallel branches plus the top of each chain) in a scratch worktree or with `git read-tree`, and confirm `git diff <original-branch> <combined-tree>` is empty. Any difference means a hunk was dropped, duplicated wrongly, or hand-edited away from the final state: fix it before proceeding. Identical duplicated prerequisite hunks across branches are expected and must match byte for byte. State any expected difference up front (for example, a file made identical to another open PR's version) and require the diff to equal exactly that, nothing more.

Original branch is left untouched throughout.

## 5. Single confirmation gate

Show the final plan as the same ASCII tree from step 3. Ask one explicit go/no-go for the **whole batch**, not per branch. Do not push or touch GitHub before this.

## 6. Push + draft PRs

On approval, for each chain/stack built in step 4: check it out (`gh stack checkout <top-branch>`) and run `gh stack submit --auto`. This pushes every branch in that stack and opens a draft PR per branch, base-chained correctly, and links them together as a GitHub Stack (so reviewers see the "stacked on #N" relationship natively — no manual note needed).

Report the created PR URLs (from `gh stack view --json` or the `submit` output).

## Out of scope

- Conflict resolution / rebasing branches against the target: don't attempt it on your own. If a group's isolated diff won't apply cleanly, stop and flag it to the user rather than guessing a resolution. Rebase the original branch only when the user asks for it (see the drift check in step 1).
- Build/lint/test validation per split branch.
- PR description generation: titles/bodies are whatever `gh stack submit --auto` derives from commit messages — keep commit subjects short and skip commit bodies to keep PRs barebones, per [REFERENCE.md](REFERENCE.md).
