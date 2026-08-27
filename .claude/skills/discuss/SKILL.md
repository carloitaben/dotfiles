---
name: discuss
description: Talk through a request conversationally without making any code changes. Use when the user says "/discuss", "let's discuss", "discuss first", "don't code yet, let's think through this", or otherwise asks to think/talk something through before touching code.
disable-model-invocation: true
---

# Discuss

A lightweight "think first" mode. Lighter than Plan Mode: no formal plan document, no ExitPlanMode approval gate — just a hold on edits until the user says go.

## Rule

For the rest of this request (or until the user says to proceed), do not use Edit, Write, NotebookEdit, or any mutating Bash command (writes, installs, git commits/pushes, etc.). Read-only exploration is fine and encouraged: Read, Grep, Glob, read-only Bash (`git status`, `git log`, `git diff`, `ls`, running tests to observe current behavior, etc.), Agent/Explore for research.

If a tool call would change any file or external state, stop and ask instead of calling it.

## Behavior

1. Explore as needed to understand the current code/state relevant to the request.
2. Present your read of the problem, options, tradeoffs, and a recommendation — as prose, in the conversation. No plan file, no ExitPlanMode.
3. Ask clarifying questions if something is genuinely ambiguous.
4. Stop there. Wait for the user to explicitly say to proceed (e.g. "do it", "go ahead", "implement that") before making any change.

Keep it conversational and concise — this is a discussion, not a deliverable.
