---
name: nitpicks-save
description: Extract every stylistic/coding correction, opinion, or preference from this session and merge it into the global NITPICKS.md. Use after a round of feedback/corrections on code style or patterns, when the user says to save/remember a nitpick, or when explicitly asked to run a nitpick save.
---

Extract every stylistic or coding correction, opinion, or preference expressed in this
session and merge it into `~/.claude/skills/nitpicks/NITPICKS.md`, condensed and deduped.

## What counts as a nitpick

- Corrections to code style, naming, structure, patterns, or abstractions
- Explicit preferences volunteered without a mistake ("always do X this way", "I like Y better")
- Rejections of an approach taken, whether or not an alternative was spelled out
- Approving call-outs of a non-obvious choice made (confirms the pattern, keep doing it)

Do NOT extract:

- One-off, task-specific decisions that don't generalize beyond this session
- Anything already covered by an existing CLAUDE.md, lint config, or formatter rule
- Pure bug fixes with no stylistic dimension

## Process

1. Read the existing `NITPICKS.md` if present (create it from scratch if missing).
2. Scan the full session transcript for corrections/opinions matching the criteria above.
3. For each one, draft a single terse bullet: the rule, then a short `Why:` only if the
   user actually gave a reason, filed under the right heading (see Format below). Also work
   out how each one would merge (new heading, new bullet, replaces an existing bullet, folds
   in as a sub-bullet, or is a pure duplicate to drop silently).
4. Present the drafted list to the user before writing anything — plain numbered list, one
   candidate per line, each tagged with its merge action (new / replaces X / folds into X).
   Ask them to confirm, edit wording, or drop any entries. Wait for their reply. Don't call
   `AskUserQuestion` for this — it's an open-ended list to react to, not a single choice.
5. Apply only the confirmed/edited candidates:
   - Reinforces an existing bullet → leave the existing one alone, don't duplicate.
   - Contradicts an existing bullet → replace the old with the new (latest correction wins).
   - Special case of a broader existing rule → fold in as a sub-bullet, not a new top-level line.
6. Keep the whole file condensed — it's a quick-reference, not a changelog. Prune anything
   that reads as redundant once the new entries are merged in.
7. Write the merged result back to `NITPICKS.md`.
8. Report a one-line summary of what was added/changed/removed. Don't dump the whole file.

If in doubt on whether a candidate qualifies at all, use `AskUserQuestion` before including
it in the step-4 list rather than presenting borderline noise.

## Format

Each entry is one line: `- <imperative rule>. Why: <reason, only if given>`

Group entries under a `##` heading by scope — language (TypeScript, Python, Shell...),
framework (React, Effect...), or domain (Git, Testing, Comments...). Reuse an existing
heading when one fits; only add a new one when nothing existing does.
