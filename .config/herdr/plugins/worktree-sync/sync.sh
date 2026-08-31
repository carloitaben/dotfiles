#!/bin/sh
# sync.sh — reconciles git worktrees against herdr workspaces.
#
# herdr only auto-links a worktree to a workspace when the worktree is
# created/opened through its own `worktree create`/`worktree open` CLI. A
# worktree added directly with `git worktree add` (lazygit's builtin worktree
# commands, or an agent shelling out to git) never goes through that path, so
# it sits unopened. Conversely `git worktree remove` never touches the herdr
# workspace that was backing it, leaving an orphaned workspace behind.
#
# This closes both gaps by polling:
#   adopt: a linked git worktree with no open_workspace_id -> `worktree open`
#   reap:  an open worktree workspace whose checkout_path no longer exists
#          as a git worktree -> `workspace close`
#
# Usage: sync.sh once   (single pass, used by the manual "sync-now" action)
#        sync.sh loop   (poll forever, used by the background daemon)

set -eu

BIN="${HERDR_BIN_PATH:-herdr}"
MODE="${1:-once}"
INTERVAL="${WORKTREE_SYNC_INTERVAL:-5}"

norm() {
  # Best-effort path normalization (resolves ../ segments and symlinks) so
  # `worktree list` paths and `workspace list` checkout_paths compare equal
  # even when one side carries an unresolved ../ segment. Falls back to the
  # raw string for a path that no longer exists on disk. Always ends in a
  # newline (realpath's own output already does; the fallback must match, or
  # concatenated output collapses multiple entries onto one line).
  realpath "$1" 2>/dev/null || printf '%s\n' "$1"
}

pass() {
  wt_json=$("$BIN" worktree list 2>/dev/null) || return 0
  ws_json=$("$BIN" workspace list 2>/dev/null) || return 0

  # Adopt: linked worktrees on disk with no open workspace yet.
  printf '%s' "$wt_json" \
    | jq -c '.result.worktrees[]? | select(.is_linked_worktree and (.open_workspace_id == null))' 2>/dev/null \
    | while IFS= read -r wt; do
        path=$(printf '%s' "$wt" | jq -r '.path')
        "$BIN" worktree open --path "$path" --no-focus >/dev/null 2>&1 || true
      done

  # Reap: open worktree workspaces whose checkout no longer exists as a
  # linked git worktree.
  live_paths=$(printf '%s' "$wt_json" \
    | jq -r '.result.worktrees[]? | select(.is_linked_worktree) | .path' \
    | while IFS= read -r p; do norm "$p"; done)

  printf '%s' "$ws_json" \
    | jq -c '.result.workspaces[]? | select(.worktree.is_linked_worktree == true)' 2>/dev/null \
    | while IFS= read -r ws; do
        ws_id=$(printf '%s' "$ws" | jq -r '.workspace_id')
        ckpath_n=$(norm "$(printf '%s' "$ws" | jq -r '.worktree.checkout_path')")
        if ! printf '%s\n' "$live_paths" | grep -Fqx -- "$ckpath_n"; then
          "$BIN" workspace close "$ws_id" >/dev/null 2>&1 || true
        fi
      done
}

if [ "$MODE" = "loop" ]; then
  while true; do
    pass
    sleep "$INTERVAL"
  done
else
  pass
fi
