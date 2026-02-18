---
description: Turn a technical decision into a structured Architecture Decision Record (ADR)
agent: plan
---

You are generating a formal Architecture Decision Record (ADR).

The goal is to transform a concrete technical decision into a durable, structured record that explains:

- The context
- The options considered
- The decision taken
- The reasoning behind it
- The long-term consequences

Decision to document:
$ARGUMENTS

This command is for documenting a decision that has already been made.

This is NOT:

- A brainstorming session
- A spec
- An implementation plan
- A code generation task
- A refactor proposal

If the decision is unclear, ambiguous, or not yet made:
STOP and ask for clarification before proceeding.

You must NOT:

- Invent requirements
- Expand scope beyond the stated decision
- Propose new architecture
- Rewrite the system

Your job is documentation, not redesign.

If you are missing rationale, consequences, alternatives, or any other context necessary to form the ADR:
Use the question tool to ask the user for more information.

---

# Output Format (Strict)

# ADR-<NNN>: <Concise Decision Title>

Status: Accepted  
Date: <YYYY-MM-DD>

---

## Context

Describe:

- The problem or constraint that required a decision
- Relevant architectural or product constraints
- Any security, scaling, or UX considerations
- Why this decision matters

Keep it factual and neutral.

---

## Decision

Clearly state what was decided.

Use direct language.

Example:

- "Access tokens are stored in memory only."
- "Refresh tokens are rotated on every use."

Avoid vague phrasing.

---

## Alternatives Considered

For each alternative:

### Option A: <Name>

- Description
- Why it was not chosen

### Option B: <Name>

- Description
- Why it was not chosen

Include at least two realistic alternatives.

---

## Rationale

Explain why the chosen option is better under current constraints.

Address:

- Security implications
- Complexity tradeoffs
- Operational cost
- Future flexibility

No fluff. No marketing tone.

---

## Consequences

### Positive

- Concrete benefits
- Reduced risks
- Improved clarity

### Negative

- Tradeoffs
- Limitations
- Operational burden
- Future migration cost

Be honest.

---

## Revisit Conditions

When should this decision be re-evaluated?

Examples:

- If the system becomes multi-tenant
- If a mobile client is introduced
- If subdomain architecture changes
- If regulatory requirements change

Make these concrete.

---

## Related Decisions

List any ADRs this depends on or influences.

If none:
State: None.

---

End with:

Would you like to:

- generate the next ADR number?
- convert this into a `/docs/adr/NNN-*.md` file?
- review and refine?
