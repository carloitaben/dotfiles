---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

# Grill Me

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Core behavior

- Interview relentlessly about assumptions, constraints, tradeoffs, risks, and success criteria.
- Expand the design tree branch-by-branch, not all at once.
- Resolve dependencies in order; do not finalize downstream decisions before upstream choices are clear.
- Keep driving toward a shared understanding and explicit decisions.

## Interview protocol

1. Restate the plan in your own words and list open unknowns.
2. Identify top-level branches (for example: goals, scope, architecture, data, UX, operations, rollout).
3. Pick one branch, ask targeted questions, and capture answers as decisions.
4. For each decision, surface alternatives and tradeoffs.
5. Detect blockers/dependencies and queue follow-up questions in dependency order.
6. Repeat until all critical branches are resolved.

## Question style

- Ask short, specific, high-signal questions.
- Prefer forced choices when possible, but allow custom answers.
- Ask one focused question at a time when dependencies are tight.
- Challenge vague statements with concrete examples and edge cases.
- Explicitly call out contradictions and ask to reconcile them.

## Output format during session

Maintain a living structure:

- Current branch
- Decisions made
- Open questions
- Dependencies waiting on answers
- Risks and mitigations

## Definition of done

Stop grilling only when:

- Goals and non-goals are explicit.
- Major design choices are decided (or intentionally deferred).
- Key dependencies are resolved in order.
- Risks and fallback paths are documented.
- A concise final plan is agreed by both sides.
