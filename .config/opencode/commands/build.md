---
description: Hand the settled plan to implementer subagent(s) running DeepSeek V4.1 Flash
---

Dispatch the implementation to the `implementer` subagent.

Scope: $ARGUMENTS

If no scope is given, implement the change we just settled on in this conversation.

Handoff protocol:

1. Write the brief first. The implementer starts with fresh context and cannot see this conversation. Each brief must stand alone: the goal, the files or areas to touch, the conventions to follow, the constraints, and what "done" looks like. Never write "as discussed above".
2. Split only along real seams. If the work divides into independent pieces that share no files and need no ordering, dispatch one implementer per piece in parallel. Otherwise dispatch a single implementer, or run them in sequence when one piece depends on another. Never give two implementers the same file.
3. Keep your own hands off the implementation. You may review, verify, and make small follow-up fixes, but the bulk of the work belongs to the subagents.
4. Verify the result against the brief. Read the diff and run the checks.
5. Report back: what changed, how it was verified, and anything the implementers flagged as a decision or blocker.
