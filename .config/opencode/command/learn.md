---
description: Extract durable rules, decisions, and learnings from the current session into a markdown memory file
agent: plan
---

You are performing structured knowledge extraction from the CURRENT SESSION.

Your goal is to capture **durable, reusable engineering knowledge**, not a transcript summary.

Analyze:
- The full conversation in this session
- Any code that was explored, drafted, modified, or discussed
- Decisions made and tradeoffs discussed
- Bugs encountered or pitfalls discovered
- Conventions observed or implied by the user
- Patterns that worked well (or failed)

Write a markdown file to:

/docs/engineering/session-learnings-!`date +%Y-%m-%d`.md

If the directory does not exist, create it.

Do NOT include noisy details. Only write what would matter 2–6 months from now.

---

# HARD RULES

- Do NOT summarize the entire conversation.
- Do NOT restate obvious background context.
- Prefer stable rules, constraints, and patterns.
- If uncertain, label it as inference.
- If nothing meaningful was learned, say so explicitly.

---

# OUTPUT FORMAT (STRICT)

# Session Learnings – !`date +%Y-%m-%d`

## High-Level Context
1–3 bullets describing what was being attempted or explored.

---

## Architectural Decisions
For each decision:

- Decision:
- Why:
- Tradeoffs:
- Future implications:

(If none, write "None recorded.")

---

## Codebase Conventions Discovered
For each convention:

- Pattern:
- Where observed:
- Why it exists (if inferred):
- Should it be preserved? (yes/no/unknown)

(If none, write "None recorded.")

---

## Engineering Rules (Explicit or Implied)
Write durable rules that should persist across sessions.

Examples:
- Always X when Y
- Never modify Z without A
- Prefer B over C because D

Include only rules worth reusing.

(If none, write "None recorded.")

---

## Known Constraints
List constraints that should influence future work:

- Technical constraints
- Compatibility constraints
- Dependency constraints
- Performance constraints
- Business/product constraints (only if they impact engineering choices)

(If none, write "None recorded.")

---

## Pitfalls / Gotchas
- What went wrong or nearly went wrong
- What to watch for next time

(If none, write "None recorded.")

---

## Open Questions Worth Revisiting
Only include strategic/architectural unknowns.

(If none, write "None recorded.")

---

## Suggested Updates to Global Build Rules (Optional)
If this session suggests improving:

/docs/engineering/constitution.md

Propose changes here as bullets.

(If none, write "None recorded.")

---

End the document with:

"Load this file as context in future sessions when working on related areas."
