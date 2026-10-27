---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

1. **See the current state** of the merge/rebase. Check git history, and the conflicting files.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, pick the one matching the merge's stated goal and note the trade-off. Do **not** invent new behaviour. Always resolve; never `--abort`.

4. Discover the project's **automated checks** and run them, typically typecheck, then tests, then format. Fix anything the merge broke.

5. **Finish the merge/rebase.** Stage everything and commit. If rebasing, continue the rebase process until all commits are rebased.

## Ask-mode

Opt-in, when the caller says so (e.g. `/conflicts`). Changes steps 3 and 5: only resolve **evident** hunks; leave the rest unresolved and brief the user.

**Evident** (auto-resolve):
- lockfiles: regenerate with the package manager
- generated files: regenerate
- import/export lists: union
- both sides add adjacent, non-overlapping lines
- whitespace/formatting-only differences
- one side a strict superset of the other
- rename vs edit: apply the edit to the renamed file

**Ask** (leave unresolved): same logic changed differently, delete vs modify, any semantic call (behavior, types, config values, migrations). When in doubt, ask.

Don't commit while any "ask" hunk remains. Stop mid-merge/rebase and return:

- every auto-resolution, one line each (file, what you did)
- one briefing per "ask" hunk:

```
❓ **Q<n>** - **<file>: <short title>**: what each side changed and why (from PR/commit intent).

➡️ <most likely resolution>
```

When answers arrive, apply them, then continue from step 4.
