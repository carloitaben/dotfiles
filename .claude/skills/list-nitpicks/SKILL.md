---
name: list-nitpicks
description: List every stylistic/coding correction, opinion, or preference from this session. Use after a round of feedback/corrections on code style or patterns, when the user says to list nitpicks.
---

List every stylistic or coding correction, opinion, or preference expressed in this
session.

## What counts as a nitpick

- Corrections to code style, naming, structure, patterns, or abstractions
- Explicit preferences volunteered without a mistake ("always do X this way", "I like Y better")
- Rejections of an approach taken, whether or not an alternative was spelled out
- Approving call-outs of a non-obvious choice made (confirms the pattern, keep doing it)

What does NOT count:

- One-off, task-specific decisions that don't generalize beyond this session
- Anything already covered by an existing CLAUDE.md, lint config, or formatter rule
- Pure bug fixes with no stylistic dimension

## Process

1. Scan the full session transcript for corrections/opinions matching the
   criteria above.
2. For each one, draft a single terse bullet: the rule, then a short `Why:` only
   if the user actually gave a reason.
3. Present the list to the user before — plain numbered list, one per line.

If in doubt on whether a candidate qualifies at all, use `AskUserQuestion`.

## Format

Each entry is one line: `- <imperative rule>. Why: <reason, only if given>`
