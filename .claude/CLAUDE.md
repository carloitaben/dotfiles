## Communication Style

- Speak simply and clearly.
- In all interaction and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
- When asked to reply, post, or rewrite, just do it. Don't walk through the reasoning first unless asked.
- When explaining code, flow, architecture, or refactors: load `show-me` skill, prefer visuals over prose.

## Code Quality

- Make minimal, surgical changes.
- Make illegal states unrepresentable: model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures.
- Every optional field is a question the rest of the codebase has to answer each time it's touched. Be intentional before adding one.
- Choose architecture over minimal diff. Skip legacy/back-compat fallbacks unless explicitly told to keep them.
- Prefer browser verification over adding new tests for UI bugs unless tests are requested.
- Beautiful is better than ugly.
- Explicit is better than implicit.
- Simple is better than complex.
- Complex is better than complicated.
- Flat is better than nested.
- Sparse is better than dense.
- Readability counts.
- Special cases aren't special enough to break the rules.
- Although practicality beats purity.
- Errors should never pass silently. Unless explicitly silenced.
- In the face of ambiguity, refuse the temptation to guess.
- There should be one-- and preferably only one --obvious way to do it.
- Although that way may not be obvious at first unless you're Dutch.
- Now is better than never.
- Although never is often better than _right_ now.
- If the implementation is hard to explain, it's a bad idea.
- If the implementation is easy to explain, it may be a good idea.
- Namespaces are one honking great idea.

Fight entropy. Leave the codebase better than you found it.

## Code Structure

- Code that changes together should live together.
- Start with the smallest useful vertical, usually a route, page, domain, or shared product area.
- Prefer vertical/feature structure over grouping by technical type (`components`/`hooks`/`utils`/`types`).
- Shared code must earn its place. A real shared vertical or the design system, not a generic `utils` dump.
- Give each vertical a small public surface. Default internals to private. Avoid deep imports across verticals.

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.
- Never escape backticks in PR bodies, PR comments, or review replies. Write the body to a temp file with a quoted heredoc (cat <<'EOF' > /tmp/body.md) and pass it with `--body-file`.

## Skills

- Browser debugging/verification (including React re-renders): load `agent-browser` skill.
- Operate desktop apps: Use `agent-desktop` to see and operate desktop apps. Before the first use, run `agent-desktop skills get desktop` and `agent-desktop skills get platform`, and follow them.
- Dependency source: MANDATORY, NON-NEGOTIABLE: never read `node_modules/` to understand a package. Load `opensrc` skill, source lives only at `~/.opensrc/`.

## Shell environment

- This is macOS (BSD sed, zsh). Use `sed -i ''`, not `sed -i`, or prefer the Edit tool for file changes.
- Quote globs and special characters for zsh.
