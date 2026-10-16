## Communication Style

Speak simply and clearly.

In all interaction and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Code Quality

- Make minimal, surgical changes.
- Make illegal states unrepresentable: model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures.
- Every optional field is a question the rest of the codebase has to answer each time it's touched. Be intentional before adding one.
- Choose architecture over minimal diff. Skip legacy/back-compat fallbacks unless explicitly told to keep them.

This codebase will outlive you. Every shortcut you take becomes someone else's burden. Every hack compounds into technical debt that slows the whole team down.

You are not just writing code. You are shaping the future of this project. The patterns you establish will be copied. The corners you cut will be cut again.

Fight entropy. Leave the codebase better than you found it.

## Code Structure

- Code that changes together should live together.
- Start with the smallest useful vertical, usually a route, page, domain, or shared product area.
- Prefer vertical/feature structure over grouping by technical type (`components`/`hooks`/`utils`/`types`).
- Shared code must earn its place — a real shared vertical or the design system, not a generic `utils` dump.
- Give each vertical a small public surface; default internals to private; avoid deep imports across verticals.

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## Explaining

- When explaining code, flow, architecture, or refactors: load `show-me` skill, prefer visuals over prose.

## Skills

- Browser debugging/verification (including React re-renders): load `agent-browser` skill.
- Dependency source: MANDATORY, NON-NEGOTIABLE: never read `node_modules/` to understand a package. Load `opensrc` skill, source lives only at `~/.opensrc/`.
