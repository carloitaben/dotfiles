#!/bin/bash
# Swap the tracked files that differ from <base-ref> (committed or not) to their
# <base-ref> version, and back. The working-tree versions are backed up and restored
# byte for byte, so uncommitted edits survive.
# Usage: base.sh on <base-ref> | base.sh off
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
state="$(git rev-parse --git-dir)/shots-swap"

case "${1:-}" in
  on)
    base="${2:?usage: base.sh on <base-ref>}"
    [ -e "$state.list" ] && { echo "already swapped; run 'base.sh off' first" >&2; exit 1; }
    git diff --name-only --diff-filter=M "$base" > "$state.list"
    [ -s "$state.list" ] || { echo "no modified files against $base" >&2; rm -f "$state.list"; exit 1; }
    tar -cf "$state.tar" -T "$state.list"
    xargs git restore --source="$base" --worktree -- < "$state.list"
    echo "swapped $(wc -l < "$state.list" | tr -d ' ') files to $base"
    ;;
  off)
    [ -e "$state.list" ] || { echo "nothing swapped" >&2; exit 1; }
    tar -xf "$state.tar"
    rm -f "$state.list" "$state.tar"
    echo "restored"
    git status --short
    ;;
  *)
    echo "usage: base.sh on <base-ref> | base.sh off" >&2
    exit 1
    ;;
esac
