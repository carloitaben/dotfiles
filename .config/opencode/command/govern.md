---
description: Define or update global engineering build rules for this project
agent: plan
subtask: true
---

You are defining or refining the global engineering build rules for this project.

Additional context (optional):
$ARGUMENTS

If a rules file already exists at:

/docs/engineering/constitution.md

Load it and improve it rather than replacing it.
If it does not exist, create it.

Your goal is to define durable, reusable rules that:

- Guide implementation behavior
- Enforce quality standards
- Reduce architectural drift
- Prevent unsafe or sloppy changes
- Reflect the user's engineering philosophy

These rules must be stable across sessions and reusable by AI agents.

---

# RULE DESIGN PRINCIPLES

Rules must be:

- Clear
- Enforceable
- Durable (should still make sense in 6+ months)
- Architecture-aware
- Written as imperatives

Avoid:
- Overly specific one-off rules
- Temporary session details
- Redundant or obvious statements

---

# OUTPUT STRUCTURE (STRICT)

Write or update the file:

/docs/engineering/constitution.md

With the following structure:

# Global Engineering Build Rules

## Core Philosophy
Short paragraph summarizing the engineering stance
(e.g., small changes, explicit tradeoffs, clarity over cleverness, etc.)

---

## Implementation Discipline

- One logical change per PR.
- Do not modify unrelated code.
- Avoid drive-by refactors.
- Prefer readability over clever abstractions.
- Add or update tests for new behavior.

(Add or refine as appropriate.)

---

## Architectural Integrity

- Respect existing layer boundaries.
- Do not introduce cross-layer dependencies without justification.
- Prefer dependency injection over hard coupling.
- Keep core logic framework-agnostic where possible.

(Add or refine based on project style.)

---

## Change Safety

- Preserve backward compatibility unless explicitly approved.
- Clearly explain tradeoffs in PR descriptions.
- Flag risky assumptions.
- Prefer incremental, reversible changes.

---

## Agent-Specific Rules

- Do not invent requirements not present in the spec.
- If uncertain, ask instead of guessing.
- Surface ambiguities before implementing.
- Stop and request approval if scope expands.

---

## When to Escalate

Describe conditions under which the agent must stop and request approval
(e.g., schema changes, cross-cutting refactors, dependency upgrades, etc.)

---

If the existing file is present:

- Merge thoughtfully.
- Remove duplication.
- Improve clarity.
- Strengthen weak rules.
- Preserve intentional philosophy.

---

After writing or updating the file, end with:

Global build rules updated. Would you like to review or refine them?
