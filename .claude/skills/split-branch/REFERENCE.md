# Isolating a group's changes onto its own branch

Pick the simplest mechanic that fits the group; try them in this order.

## A. Commits map 1:1 to the group

If the group corresponds cleanly to one or more whole commits from the original branch:

```
git checkout -b <group-branch> <base-or-parent-branch>
git cherry-pick <commit1> <commit2> ...
```

Fastest and preserves original commit messages/authorship.

## B. Group owns whole files, but commits are tangled

```
git checkout -b <group-branch> <base-or-parent-branch>
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

## Stacking

A dependent group branches off its dependency's branch, not the shared base:

```
git checkout -b <group-b-branch> <group-a-branch>
```

Its eventual PR's base is `<group-a-branch>`, not the target branch — so the PR only shows group B's diff. Once group A merges, GitHub retargets group B's PR automatically (or the user retargets manually); this skill doesn't handle that follow-up.

# Draft PR body template

Keep it barebones — title and structure only, no generated prose:

```
Stacked on #<parent-pr-number> (branch: <parent-branch>)
```

Omit the "Stacked on" line entirely for independent groups. Never add a description, testing section, or ticket reference — those are left for the user to fill in.
