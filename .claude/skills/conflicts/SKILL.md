---
name: conflicts
description: Resolve merge conflicts on one or more PRs/branches in parallel worktrees.
disable-model-invocation: true
---

Dispatch conflict resolution; do not resolve conflicts in the dispatcher.

## 1. Plan

Run `python3 <skill-directory>/scripts/plan.py [PR-number|PR-URL|branch ...]` in the target repository; no arguments means the current branch. The read-only planner groups open PRs into bottom-up units. Stop and report any error; do not infer missing members. For a non-default base without a matching open PR, the agent must verify that `gh-stack` can handle it, or fail the unit.

## 2. Dispatch

Dispatch one subagent per unit in parallel, never parallel within a stack. Give each the complete unit and instruct it to read and follow [AGENT.md](AGENT.md). Wait until every agent has reported.

## 3. Brief and resume

Gather all `needs-input` briefings into one round, numbered across targets (`PR#12 Q1`), using the Ask-mode format. Wait for answers, then resume each waiting subagent with its answers. Repeat until every unit is `clean`, `pushed`, or `failed`.

## 4. Report

Table, one row per target: PR/branch link, status, auto-resolved count, push result, and any retained worktree path. Include partial stack pushes and unpushed local changes.
