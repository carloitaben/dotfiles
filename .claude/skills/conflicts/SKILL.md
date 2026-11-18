---
name: conflicts
description: Resolve merge conflicts on one or more PRs/branches in parallel worktrees.
disable-model-invocation: true
---

You are the dispatcher: plan, dispatch, relay questions, report. Subagents resolve the conflicts.

## 1. Plan

The user's arguments are free-form text; they never type flags. Translate what they asked for into a `plan.py` call in the target repository: `python3 <skill-directory>/scripts/plan.py`. The target is a PR (a standalone PR or any member of a stack):

- A PR number, URL or branch plans that PR.
- No arguments plans the PR of the current branch. No open PR for it: report that and stop.
- `--conflicting` (with `--draft`) finds your conflicting PRs and plans them.

The planner stops on PRs authored by someone else. Add `--allow-others` only after the user explicitly consents to that PR's author being someone else; ask when unsure.

The planner prints **units**: `standalone` (one PR) or `stack` (chained PRs). Report any planner error and stop; the planner never guesses missing members. Name the PRs in `mergeabilityUnknown`: GitHub had not finished computing them. `--help` lists the rest.

Each branch carries `local.blockers`. Ask the user what to do with every blocked branch (continue, skip, or they fix it first). Done when every unit is dispatchable or skipped.

## 2. Dispatch

One subagent per unit, in parallel across units. Give each the complete unit, the absolute `<skill-directory>`, and the instruction to read and follow [AGENT.md](AGENT.md). Done when every agent has reported.

## 3. Brief and resume

Gather every `needs-input` briefing into one round, numbered across targets (`PR#12 Q1`), in the Ask-mode format. Resume each waiting agent with its answers. Done when every unit is `clean`, `pushed`, or `failed`.

## 4. Report

Pipe the agents' result JSON, as one array, to `python3 <skill-directory>/scripts/report.py` and show the table. Below it, say only what the table cannot: resolutions that moved code beyond import fixes, checks that failed, partial stack pushes, unpushed local changes.