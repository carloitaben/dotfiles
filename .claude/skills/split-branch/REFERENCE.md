# Isolating a group's changes onto its own branch

Branch creation and switching is handled by `gh stack init` / `gh stack add` (see [SKILL.md](SKILL.md) step 4) — by the time you get here, the group's target branch already exists and is checked out. These mechanics only cover getting the right diff onto that branch. Pick the simplest one that fits the group; try them in this order.

## A. Commits map 1:1 to the group

If the group corresponds cleanly to one or more whole commits from the original branch:

```
git cherry-pick <commit1> <commit2> ...
```

Fastest and preserves original commit messages/authorship.

## B. Group owns whole files, but commits are tangled

```
git checkout <original-branch> -- <file1> <file2> ...
git add <file1> <file2> ...
git commit -m "<feature summary>"
```

Repeat the checkout/add for every file the group owns. This takes whichever version of each file exists at the tip of the original branch, so it's only correct when the group owns the *entire* file (no other group touches it).

## C. Two groups touch the same file (hunk-level split)

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

# Keeping PRs barebones under gh-stack

`gh stack submit --auto` (step 6) derives each PR's title/body from that branch's commits, per its own rules:

- Single commit on the branch → PR title = commit subject, PR body = commit body.
- Multiple commits on the branch → PR title = humanized branch name, no generated body.

To keep PRs barebones, commit each group as a **single commit with a short subject and no body** — this yields a PR with just that subject as the title and an empty body, no generated prose, no test plan, no ticket content. Base-branch chaining and the "stacked on" relationship are handled natively by gh-stack's Stack linking (visible in the GitHub UI) — don't add a manual "Stacked on #N" note.
