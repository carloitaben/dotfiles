# Landing a group's state on its branch

The group's branch already exists and is checked out ([SKILL.md](SKILL.md) step 4). Land its state as one fresh commit (subject-only, per SKILL.md). Cherry-picking drags in old message, authorship and chronology; the split reflects final-state ownership. Pick the first option that fits.

## A. Group owns whole files

```
git checkout <original-branch> -- <file1> <file2> ...
git add <file1> <file2> ...
git commit -m "<feature summary>"
```

Takes each file as at the original tip: correct only when no other group touches it.

## B. Two groups touch the same file (hunk split)

No git command splits a diff by hunk non-interactively. Build the patch by hand:

```
git diff <merge-base> <original-branch> -- <file> > <scratchpad>/full.patch
```

Delete the other groups' `@@` blocks, then `git apply` it, `git add <file>`, commit.

Error-prone: tell the user which file is hunk-split and where each hunk goes before committing. Inseparable hunks (one depends on another) fold into one group.

## C. Conceptual slice (hand-authored state)

For one concept spread across files other groups also touch (a shell component hosting features A, B, C), a diff slice isn't coherent. Start from the previous branch's state and hand-edit each file to what this group leaves behind: this group's code only, later groups' left out. Each later branch adds its slice, so the chain's last branch ends byte-identical to the original file.

Reliable authoring: start from the final file's text and apply `replace` operations asserting each anchor occurs exactly once, removing later groups' code (imports, helpers, JSX, props). A missing anchor fails loudly instead of yielding a wrong file. Barrel files (`index.ts`) need one state per group, exporting only what exists so far.

- Each state should typecheck and make sense alone where practical.
- Prerequisite hunks shared with a parallel PR (config entry, shared type, shared prop) are copied verbatim.
- Tell the user which files are hand-authored before committing.
- Losslessness check (SKILL.md step 4) is mandatory afterward.
