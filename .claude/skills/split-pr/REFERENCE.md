# Isolating a group's changes onto its own branch

Branch creation and switching is handled by `gh stack init` / `gh stack add` (see [SKILL.md](SKILL.md) step 4). By the time you get here, the group's target branch already exists and is checked out. These mechanics only cover getting the right diff onto that branch, always as a single fresh commit. Never cherry-pick original commits onto it, even when a group happens to map 1:1 to one: cherry-picking preserves the original commit's message, authorship, and place in the old chronology, which is exactly what we're avoiding. The split reflects final-state ownership, not history. Pick the simplest one that fits the group; try them in this order.

## A. Group owns whole files

```
git checkout <original-branch> -- <file1> <file2> ...
git add <file1> <file2> ...
git commit -m "<feature summary>"
```

Repeat the checkout/add for every file the group owns. This takes whichever version of each file exists at the tip of the original branch, so it's only correct when the group owns the *entire* file (no other group touches it).

## B. Two groups touch the same file (hunk-level split)

No single git command splits a file's diff by hunk non-interactively. Construct the patch by hand:

```
git diff <merge-base> <original-branch> -- <file> > /tmp/full.patch
```

Edit the patch to keep only the hunks belonging to this group (drop the other hunks' `@@ ... @@` blocks and their lines), then:

```
git apply /tmp/full.patch
git add <file>
git commit -m "<feature summary>"
```

This is manual and error-prone — before doing it, tell the user which file is being hunk-split and which hunks go where, so they can catch a bad split before it's committed. If a file's hunks are genuinely inseparable (e.g. one hunk depends on another), fold them into the same group instead of forcing a split.

## C. Conceptual slice (hand-authored intermediate state)

When a feature group is one concept spread across files that other groups also touch (e.g. a shell component that hosts features A, B and C), a pure diff slice isn't coherent. Instead, start from the previous branch's state and edit the files by hand to the state this group should leave behind: add only this group's code, leave later groups' code out. Each later branch adds its slice on top, so the last branch in the chain ends byte-identical to the original file.

How to author a state reliably: start from the final file's text and apply `replace` operations that assert each anchor occurs exactly once, removing later groups' code (imports, helpers, JSX, props). A missing anchor then fails loudly instead of silently producing the wrong file. Barrel files (`index.ts`) usually need one state per group, each exporting only what exists so far.

Rules:
- Every intermediate state should typecheck and make sense on its own where practical.
- Prerequisite hunks that also live in a parallel PR (config entry, shared type, shared prop) are copied verbatim, so they vanish from the diff once the parallel PR merges.
- Tell the user which files are being hand-authored before committing.
- The step 4 losslessness check is mandatory after this option.

# Keeping PRs barebones under gh-stack

`gh stack submit --auto` (step 6) derives each PR's title/body from that branch's commits, per its own rules:

- Single commit on the branch → PR title = commit subject, PR body = commit body.
- Multiple commits on the branch → PR title = humanized branch name, no generated body.

To keep PRs barebones, commit each group as a **single commit with a short subject and no body**. This yields a PR with just that subject as the title and an empty body: no generated prose, no test plan, no ticket content. Base-branch chaining and the "stacked on" relationship are handled natively by gh-stack's Stack linking (visible in the GitHub UI); don't add a manual "Stacked on #N" note.
