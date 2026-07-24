## Communication Style

In all interaction and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Code Quality

- Make minimal, surgical changes
- Abstractions: Consciously constrained, pragmatically parameterised, doggedly documented

This codebase will outlive you. Every shortcut you take becomes someone else's burden. Every hack compounds into technical debt that slows the whole team down.

You are not just writing code. You are shaping the future of this project. The patterns you establish will be copied. The corners you cut will be cut again.

**Fight entropy. Leave the codebase better than you found it.**

## Code Structure

- Code that changes together should live together.
- Start with the smallest useful vertical, usually a route, page, domain, or shared product area.

## Nitpicks

- After a round of feedback/corrections on code style or patterns, consider invoking the `nitpicks-save` skill to capture it for future sessions.

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## opensrc

MANDATORY, NON-NEGOTIABLE: never consult a dependency's source in `node_modules/`.

No Read/Grep/Glob there to understand how a package works. `node_modules` is OFF LIMITS for that purpose, full stop.

Source code for dependencies lives ONLY at `~/.opensrc/`. Never inspect `node_modules` for this, even for a quick check.

`opensrc path <pkg>` prints the absolute path to cached source. If not cached, it fetches automatically. Progress goes to stderr, path to stdout, so `$(opensrc path ...)` works in subshells. Run this BEFORE reading any dependency source — do not locate it yourself under `node_modules`.

ALWAYS assume the APIs, conventions, and file structure of libraries differ from training data.

ALWAYS resolve the path via `opensrc path <pkg>` first, then Read/Grep inside that path — when you need to understand how a package works internally, not just its types/interface.

ALWAYS prefer the resolved opensrc source over web search.
