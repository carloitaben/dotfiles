# Research: herdr + git worktree community patterns

Type: research
Status: resolved

## Question

How do people currently integrate git worktrees with herdr (or comparable
tmux-like terminal multiplexers) for AI-agent-driven development? Specifically:
when an agent is told "use a worktree for this," what tooling, hooks, or scripts
exist to automatically spin up a new worktree plus a corresponding herdr
tab/session for it? Survey herdr's plugin API/CLI/socket API, herdr's community
(discussions, example configs, plugins), and any general prior art for
worktree-per-session workflows (tmux + git worktree scripts, etc). Report
concrete options with tradeoffs, not just "it's possible."

## Answer

Full findings: `.scratch/nvim-herdr-migration/research/herdr-worktree-patterns.md`
on branch `research/herdr-worktree-patterns` (commit `85709ae`).

herdr already has **native, first-class git worktree support**:
`herdr worktree create/open/list/remove` creates a git worktree, registers it
as a herdr workspace, and opens a tab+pane at that path in one command — this
directly covers "tell an agent to use a worktree": the agent just runs the
CLI command itself. Worktree ops emit an ordered event sequence
(`workspace.created` → `tab.created` → `pane.created` → `worktree.created`)
over herdr's plugin/socket system, the extension point for anything more
automatic than a manual/agent-invoked CLI call.

Options, in increasing order of custom work:
1. **Agent runs `herdr worktree create` directly** — zero config, relies on
   the agent knowing the command (via herdr's own skill file).
2. **`herdr-plus` plugin** — subscribes to `worktree.created`/`worktree.opened`,
   auto-applies a fixed tab/pane layout from a per-repo (optionally
   per-branch) TOML file. Doesn't launch the agent itself, just lays out panes.
3. **Custom herdr plugin** (`[[events]] on = "worktree.created"` + hook
   script) or a raw socket subscription — for auto-launching the agent
   process, copying `.env`/gitignored files, etc. `workmux` (tmux-era prior
   art) is the best feature checklist if this route is taken: post-create
   hooks, file copy/symlink, auto agent-prompt injection, status in window
   title.
4. **`herdr-worktrunk`** — wraps the `worktrunk` CLI for fzf-driven
   interactive worktree switching + setup/teardown lifecycle hooks with
   `{{branch}}`/`{{worktree_path}}` templating. Useful if an interactive
   picker (vs. agent-driven) is the primary entry point.

Pre-herdr tmux prior art (context only, not directly usable): `gwt`,
`tmux-sessionizer`, `workmux`, `muxtree` (`muxtree new NAME --run claude`
creates worktree + 2-window session with the agent already running).
