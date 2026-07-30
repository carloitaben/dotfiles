## Communication Style

In all interaction and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Code Quality

- Make minimal, surgical changes.
- Abstractions: Consciously constrained, pragmatically parameterised, doggedly documented.
- Make illegal states unrepresentable: model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures.
- Every optional field is a question the rest of the codebase has to answer each time it's touched — be intentional before adding one.
- Choose architecture over minimal diff; skip legacy/back-compat fallbacks unless explicitly told to keep them.

This codebase will outlive you. Every shortcut you take becomes someone else's burden. Every hack compounds into technical debt that slows the whole team down.

You are not just writing code. You are shaping the future of this project. The patterns you establish will be copied. The corners you cut will be cut again.

**Fight entropy. Leave the codebase better than you found it.**

## Code Structure

- Code that changes together should live together.
- Start with the smallest useful vertical, usually a route, page, domain, or shared product area.
- Prefer vertical/feature structure over grouping by technical type (`components`/`hooks`/`utils`/`types`).
- Shared code must earn its place — a real shared vertical or the design system, not a generic `utils` dump.
- Give each vertical a small public surface; default internals to private; avoid deep imports across verticals.

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## agent-browser

When debugging or verifying anything that runs in a browser, use the agent-browser CLI. To view the available commands, run:

- agent-browser --help

For WebGL or any feature not available in headless mode, run agent-browser in headed mode.

Once agent-browser has been used in the conversation, assume it should keep being used for further frontend-related changes without being asked again.

When debugging React re-renders, use agent-browser's React DevTools-backed commands instead of manual console.log/profiling. Run `agent-browser --help` (and `agent-browser react --help` if available) to see the current `react ...` subcommands — don't assume a fixed list, the CLI evolves.

If an agent-browser repro turns into repeated rechecking, pause and write a Playwright test instead when the project has Playwright installed.

## opensrc

MANDATORY, NON-NEGOTIABLE: never consult a dependency's source in `node_modules/`.

No Read/Grep/Glob there to understand how a package works. `node_modules` is OFF LIMITS for that purpose, full stop.

Source code for dependencies lives ONLY at `~/.opensrc/`. Never inspect `node_modules` for this, even for a quick check.

`opensrc path <pkg>` prints the absolute path to cached source. If not cached, it fetches automatically. Progress goes to stderr, path to stdout, so `$(opensrc path ...)` works in subshells. Run this BEFORE reading any dependency source — do not locate it yourself under `node_modules`.

ALWAYS assume the APIs, conventions, and file structure of libraries differ from training data.

ALWAYS resolve the path via `opensrc path <pkg>` first, then Read/Grep inside that path — when you need to understand how a package works internally, not just its types/interface.

ALWAYS prefer the resolved opensrc source over web search.
