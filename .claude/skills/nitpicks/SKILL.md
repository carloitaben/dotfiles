---
name: nitpicks
description: Apply accumulated NITPICKS.md style/pattern corrections to files touched in this session. Use when user wants a nitpick pass, to "apply nitpicks", "check nitpicks", or before wrapping up a session with edited files.
---

Apply saved personal style corrections (accumulated over past sessions via
`/nitpicks-save`) to the files this session has touched.

## Process

1. Read [NITPICKS.md](~/.claude/skills/nitpicks/NITPICKS.md). If it's missing or has no
   real entries yet, tell the user there's nothing to apply and stop.
2. Determine touched files:
   - Prefer files this session already edited/created (from Edit/Write calls made so far).
   - If that's unclear, fall back to `git status` / `git diff --name-only` for uncommitted
     changes in the working directory.
3. For each touched file, pick the NITPICKS.md sections that apply to its language/
   framework/extension.
4. Read the current content of each touched file and check it against every applicable rule.
5. Edit in place to fix violations. These are style/pattern fixes, not refactors — preserve
   behavior.
6. Skip rules that don't apply to a file's stack. Skip files with no applicable section.
7. Report which files changed and which rule triggered each change, one line per file. If
   nothing needed fixing, say so — don't force a change.

## Rules

- Don't invent new nitpicks here — only apply what's already in NITPICKS.md. New corrections
  go through `/nitpicks-save`.
- Don't touch files outside the touched-files set, even if they'd also violate a rule.
- If a rule conflicts with an explicit instruction already given this session, the session
  instruction wins — skip the rule and say why.
