---
name: split-branch
description: Interactively split a git branch/PR into multiple smaller feature branches, auto-detecting dependencies between them and stacking accordingly, then pushing and opening barebones draft PRs after a single confirmation. Use when the user wants to split a branch or PR, break a large diff into smaller PRs, or mentions "split this branch/PR".
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

Present the plan, along with branch names, via AskUserQuestion and iterate: let the user merge/split groups, reassign files, rename branches, or change dependency edges. Loop until confirmed. **No git writes yet.**

## 4. Build local branches

Topologically order groups by dependency. For each, in order:

- Branch off the **base** if independent, or off the **parent group's branch** if dependent (stacking).
- Isolate that group's changes onto the new branch. See [REFERENCE.md](REFERENCE.md) for the cherry-pick vs. per-file vs. per-hunk mechanics — pick the simplest one that fits the group.
- Commit with a message derived from the group's feature summary.

Original branch is left untouched throughout.

## 5. Single confirmation gate

Show the final plan: branch names, stack order, base for each, file counts. Ask one explicit go/no-go for the **whole batch** — not per branch. Do not push or touch GitHub before this.

## 6. Push + draft PRs

On approval, push branches in dependency order, then `gh pr create --draft` for each:

- **Base**: the target branch for independent groups, or the parent group's branch for stacked ones.
- **Title**: short, derived from the feature summary.
- **Body**: barebones only — see the template in [REFERENCE.md](REFERENCE.md). No generated description, no test plan, no ticket/JIRA content.

Report the created PR URLs.

## Out of scope

- Conflict resolution / rebasing branches against the target: don't attempt it. If a group's isolated diff won't apply cleanly, stop and flag it to the user rather than guessing a resolution.
- Build/lint/test validation per split branch.
- PR description generation beyond the barebones template.
