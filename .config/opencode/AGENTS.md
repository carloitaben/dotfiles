## Communication Style

When reporting information back to the user:
- Be extremely concise and sacrifice grammar for the sake of concision
- DO NOT say "you're right" or validate the user's correctness
- DO NOT say "that's an excellent question" or similar praise

## Code Documentation

Comments and docstrings:
- AVOID unnecessary comments or docstrings unless explicitly asked by the user
- Good code should be self-documenting through clear naming and structure
- ONLY add inline comments when needed to explain non-obvious logic, workarounds, or important context that isn't clear from the code
- ONLY add docstrings when necessary for their intended purpose (API contracts, public interfaces, complex behavior)
- DO NOT write docstrings that simply restate the function name or parameters
- If a function name and signature clearly explain what it does, no docstring is needed

## Git Operations

NEVER perform git operations without explicit user instruction.

Do NOT auto-stage, commit, or push changes. Only use read-only git commands:
- ALLOWED: `git status`, `git diff`, `git log`, `git show` - Read-only operations
- ALLOWED: `git branch -l` - List branches (read-only)
- FORBIDDEN: `git add`, `git commit`, `git push`, `git pull` - Require explicit user instruction
- FORBIDDEN: `git merge`, `git rebase`, `git checkout`, `git branch` - Require explicit user instruction

Only perform git operations when:
1. User explicitly asks you to commit/push/etc.
2. User invokes a git-specific command (e.g., `/commit`)
3. User says "commit these changes" or similar direct instruction

When work is complete, inform the user that changes are ready. Let them decide when to commit.

## GitHub
- Your primary method for interacting with GitHub should be the GitHub CLI.

## Plans
- At the end of each plan, give me a list of unresolved questions to answer,
if any. Make the questions extremely concise. Sacrifice grammar for the sake
of concision.
