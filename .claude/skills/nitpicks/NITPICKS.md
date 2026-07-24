# Nitpicks

Condensed personal style/pattern corrections learned across coding sessions.
Populated by the `nitpicks-save` skill, applied by the `nitpicks` skill. Keep this file
short — one terse bullet per rule, grouped by scope. Prune instead of piling on.

## TypeScript

- Never use `any`, non-null assertion (`!`), or type assertions (`as Type`) — fix the type instead.
- Make illegal states unrepresentable: model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures.
- Every optional field is a question the rest of the codebase has to answer each time it's touched — be intentional before adding one.

## Code Structure

- Prefer vertical/feature structure over grouping by technical type (`components`/`hooks`/`utils`/`types`).
- Shared code must earn its place — a real shared vertical or the design system, not a generic `utils` dump.
- Give each vertical a small public surface; default internals to private; avoid deep imports across verticals.

```
Bad: same concern separated by API type
.
└── src/
    ├── hooks/
    │   └── useMediaQuery.ts
    ├── types/
    │   └── media.ts
    └── utils/
        └── mediaQueryObserver.ts

Good: hooks, types, utilities… all in the same file
.
└── src/
    └── lib/
        └── media.ts
```

## Architecture

- Choose architecture over minimal diff; skip legacy/back-compat fallbacks unless explicitly told to keep them.

## Testing

- Tests should verify semantically correct behavior; a failing test that exposes a genuine bug is fine to leave failing.
- If an `agent-browser` repro turns into repeated rechecking, pause and write a Playwright test instead when the project has Playwright installed.

## Comments

- Don't narrate the bug or task being fixed in a comment (e.g. "use `.click()`, not `.focus()` — because focusing a button doesn't also trigger it, unlike native label-click semantics"). If it's inferable from reading the code in context, skip it entirely — a comment should capture a genuinely non-obvious invariant, not restate the diff's own story. Why: reads as leftover task narration 6 months later, not documentation.
