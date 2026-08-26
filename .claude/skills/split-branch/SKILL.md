---
name: split-branch
description: Interactively split a git branch/PR into multiple smaller feature branches, auto-detecting dependencies between them and stacking accordingly, then pushing and opening barebones draft PRs after a single confirmation. Use when the user wants to split a branch or PR, break a large diff into smaller PRs, or mentions "split this branch/PR".
disable-model-invocation: true
---

Split the diff between the current branch and its target into multiple independent (or stacked) branches + draft PRs. Never push or open a PR without the single confirmation in step 5 — everything before that is local and reversible.

## 1. Determine base

- Base = the branch this one will eventually merge into. Try `git rev-parse --abbrev-ref --symbolic-full-name @{u}`'s remote HEAD, or the repo's default branch (`gh repo view --json defaultBranchRef`). Ask the user if ambiguous.
- Compute `git merge-base <base> HEAD`. Everything after this commit is in scope.

## 2. Gather signal

- `git log <merge-base>..HEAD --stat` for commit boundaries and messages.
- Full `git diff <merge-base>..HEAD` for content.
- Don't rely on file paths alone — a single package can contain two unrelated features, and one feature can span packages.

## 3. Propose groupings

Using both commit boundaries and diff content, propose named feature groups covering every changed file/hunk (no leftovers — anything not obviously part of a feature becomes its own group, never silently dropped). For each group note which files/hunks it owns, and whether it depends on another group's code being present (dependency = stacking edge, not just "related").

Present the plan as an ASCII tree — base branch as root, independent groups as its children, dependent groups nested under their parent group (nesting = stacking order). Annotate each node with file/hunk count. Example:

```
main
├── auth-refactor (12 files)
├── api-pagination (5 files)
└── ui-cleanup (8 files)
    └── ui-cleanup-tests (3 files)
```

Show this tree via AskUserQuestion and iterate: let the user merge/split groups, reassign files, rename branches, or change dependency edges — redraw the tree each round. Loop until confirmed. **No git writes yet.**

## 4. Build local branches via gh-stack

Use the [gh-stack](../gh-stack/SKILL.md) skill for all branch creation, switching, and stacking — never `git checkout -b` these branches by hand.

gh-stack stacks are strictly linear (one parent, one child per branch). So first partition the step-3 tree into **chains**: each independent (top-level) group plus everything nested under it is one chain = one stack rooted at base. Sibling top-level groups become *separate* stacks, not branches of the same stack.

For each chain, in dependency order:

- First branch in the chain: `gh stack init --base <base> <branch-name>` (creates the stack, branches off base, checks it out). If starting a second/third chain, first `gh stack checkout <base>` (or `gh stack trunk` if already in a stack) so you're not sitting on a branch shared by another stack.
- Each subsequent (dependent) branch in the same chain: `gh stack add <branch-name>` (must be run from the current top of that stack).
- Once the branch is created and checked out, isolate that group's changes onto it. See [REFERENCE.md](REFERENCE.md) for the cherry-pick vs. per-file vs. per-hunk mechanics — pick the simplest one that fits the group.
- `git add` the isolated files and `git commit` with a short message derived from the group's feature summary (subject line only — see the PR body note in [REFERENCE.md](REFERENCE.md)).

Original branch is left untouched throughout.

## 5. Single confirmation gate

Show the final plan as the same ASCII tree from step 3. Ask one explicit go/no-go for the **whole batch** — not per branch. Do not push or touch GitHub before this.

## 6. Push + draft PRs

On approval, for each chain/stack built in step 4: check it out (`gh stack checkout <top-branch>`) and run `gh stack submit --auto`. This pushes every branch in that stack and opens a draft PR per branch, base-chained correctly, and links them together as a GitHub Stack (so reviewers see the "stacked on #N" relationship natively — no manual note needed).

Report the created PR URLs (from `gh stack view --json` or the `submit` output).

## Out of scope

- Conflict resolution / rebasing branches against the target: don't attempt it. If a group's isolated diff won't apply cleanly, stop and flag it to the user rather than guessing a resolution.
- Build/lint/test validation per split branch.
- PR description generation: titles/bodies are whatever `gh stack submit --auto` derives from commit messages — keep commit subjects short and skip commit bodies to keep PRs barebones, per [REFERENCE.md](REFERENCE.md).
