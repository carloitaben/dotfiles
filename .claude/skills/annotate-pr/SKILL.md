---
name: annotate-pr
description: Turn the decisions and discussions from the current session into inline PR comments (self-review annotations) on the lines they affect, for one PR or a whole stack.
disable-model-invocation: true
---

Turn decisions from this session into inline review comments, so reviewers get the "why" next to the code. Source is the conversation, not the diff. Posting is outward-facing: never post before the user approves the list.

## 1. Gather decisions

Collect what was decided or discussed in this session (or in a notes file the user points to):

- choices, with the rejected alternative and why
- behavior explained or debated
- deliberate deviations from spec/ticket
- accepted trade-offs
- open questions for a reviewer

**Nothing found: stop.** Say "No decisions or discussion in this session to annotate", suggest the user paste decisions or point to a notes file. Never fill the gap by reading the diff.

## 2. Scope

- Default: current branch's PR (`gh pr view --json number,headRefName,headRefOid,baseRefName,body`).
- User-named PRs or a stack (`gh stack view --json`): all in scope, minus exclusions.

## 3. Map to lines

Per PR: diff against its base (`git diff origin/<base>...<head>`), skip generated files, read the PR body.

Keep a decision only if it maps to a line the PR adds or changes, and a reviewer would otherwise question or miss it. Drop anything the PR body already says, and anything that just describes visible code. Fewer, sharper comments. No match, no comment.

Use only reasons stated in the session. Inferred rationale becomes a `[!TIP]` question.

## 4. Draft and confirm

One point per comment, anchored to one added line. Open the body with a GitHub alert, then the text on the following `>` lines:

- `> [!NOTE]` fact
- `> [!IMPORTANT]` decision a reviewer could push back on
- `> [!TIP]` open question
- `> [!WARNING]` gotcha: breaks if changed

Example body: `> [!NOTE]\n> The outline is on the row, not the control.`

Short, plain, no first person, no emoji, backticks for identifiers.

Show a table: PR, `file:line`, alert type, text. Ask where unsure, esp. inferred rationale and gotchas that belong in a code comment instead (review comments vanish after merge). **Post nothing until approved.**

## 5. Post

Write approved comments to JSON, run [post-comments.py](post-comments.py) with `dry` (fix any `BAD`), then `post`.

- One inline comment each on the PR's head commit via `gh api .../pulls/<n>/comments`. Not `gh pr review` (creates pending review).
- Line numbers refer to the file at that PR's head. In a stack, compute per branch.
- Pushing again can outdate comments: post last.

Report comment URLs and count per PR.
