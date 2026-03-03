## Communication Style

- In all interaction and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Language Corrections

English is not the user’s first language.

If the user writes unnatural or incorrect English, provide a brief correction in one short line.

Format:

> ✏️ Language tip: “original phrase" → "corrected phrase"

- Only correct noticeable mistakes in words and phrases.
- Do not correct casing mistakes.
- Do not derail the conversation.
- Then continue with the normal response.

## Code Quality

- Make minimal, surgical changes
- Never compromise type safety: no `any`, no non-null assertion operator (`!`), no type assertions (`as Type`)
- Make illegal states unrepresentable: model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures; if state can't exist, code can't mishandle it
- Abstractions: Consciously constrained, pragmatically parameterised, doggedly documented

This codebase will outlive you. Every shortcut you take becomes
someone else's burden. Every hack compounds into technical debt
that slows the whole team down.

You are not just writing code. You are shaping the future of this
project. The patterns you establish will be copied. The corners
you cut will be cut again.

**Fight entropy. Leave the codebase better than you found it.**

## Testing

- Write tests that verify semantically correct behavior
- Failing tests are acceptable when they expose genuine bugs and test correct behavior

## Code Documentation

Comments and docstrings:

- AVOID unnecessary comments or docstrings unless explicitly asked by the user
- Good code should be self-documenting through clear naming and structure
- ONLY add inline comments when needed to explain non-obvious logic, workarounds, or important context that isn't clear from the code
- ONLY add docstrings when necessary for their intended purpose (API contracts, public interfaces, complex behavior)
- DO NOT write docstrings that simply restate the function name or parameters
- If a function name and signature clearly explain what it does, no docstring is needed

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## agent-browser

When the user requests debugging in the browser, use the agent-browser CLI. To view the available commands, run:

- agent-browser --help

## opensrc

Source code for dependencies is available in opensrc/ for deeper understanding of implementation details.

See opensrc/sources.json for the list of available packages and their versions.

Use this source code when you need to understand how a package works internally, not just its types/interface.

Do this when the user asks questions about a package or repository. Always prefer to consult the source code before searching the web.

To fetch the source code for a package or repository not available in opensrc/, ask the user to run:

```sh
npx opensrc <package> # npm package (e.g., npx opensrc zod)
npx opensrc pypi:<package> # Python package (e.g., npx opensrc pypi:requests)
npx opensrc crates:<package> # Rust crate (e.g., npx opensrc crates:serde)
npx opensrc <owner>/<repo> # GitHub repo (e.g., npx opensrc vercel/ai)
```
