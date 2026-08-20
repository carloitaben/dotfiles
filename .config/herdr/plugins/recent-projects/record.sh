#!/bin/sh
# record.sh — herdr `workspace.created` event hook.
# Bumps the newly-created workspace's project dir to the front of
# ~/.config/herdr/recent_projects (most-recent-first, deduped). The fzf picker
# (open-recent-repo) only records opens made *through* the picker, so this hook
# is what catches everything else: `herdr workspace create`, `herdr worktree
# create`, and agent-driven `herdr worktree open`.

set -eu

HIST="$HOME/.config/herdr/recent_projects"
BIN="${HERDR_BIN_PATH:-herdr}"
event="${HERDR_PLUGIN_EVENT_JSON:-}"

# Resolve the project dir. Worktree checkouts carry a checkout_path in the
# event payload; plain `workspace create` doesn't, so ask herdr for the
# workspace's root-pane cwd instead.
path=$(printf '%s' "$event" | jq -r '.data.workspace.worktree.checkout_path // empty' 2>/dev/null)
if [ -z "$path" ]; then
  ws_id=$(printf '%s' "$event" | jq -r '.data.workspace.workspace_id // empty' 2>/dev/null)
  if [ -n "$ws_id" ]; then
    path=$("$BIN" pane list --workspace "$ws_id" 2>/dev/null \
      | jq -r '.result.panes[]?.cwd // empty' | head -n1)
  fi
fi
[ -n "$path" ] || exit 0

# `herdr worktree create` fires workspace.created for the source repo *and* the
# checkout back-to-back, so two hooks can run concurrently. A mkdir lock plus a
# per-invocation tmp file keeps their read-modify-write from racing.
lock="$HIST.lock"
tries=0
until mkdir "$lock" 2>/dev/null; do
  tries=$((tries + 1))
  [ "$tries" -lt 200 ] || exit 0
  sleep 0.01
done
tmp="$HIST.tmp.$$"
trap 'rmdir "$lock" 2>/dev/null; rm -f "$tmp"' EXIT

touch "$HIST"
{ printf '%s\n' "$path"; grep -Fvx -- "$path" "$HIST" || true; } > "$tmp"
mv -f "$tmp" "$HIST"
