#!/bin/bash
# PostToolUse hook for Edit|Write|MultiEdit: tsc --noEmit for the owning package when a TS/JS file changed.
# Runs for the whole package (not scoped to the edited file) since type errors can surface anywhere in it.
# Exits 2 with the errors on stderr so Claude sees them as blocking feedback, not exit 1 which is silent.

read_file_path() {
  jq -r '.tool_input.file_path // .tool_response.filePath // empty'
}

is_ts_or_js() {
  case "$1" in
    *.js|*.jsx|*.ts|*.tsx) return 0 ;;
    *) return 1 ;;
  esac
}

# Nearest ancestor (up to the git root) that has its own node_modules/.bin —
# handles pnpm/yarn workspaces where each app/package has its own toolchain
# and tsconfig.json instead of a single one at the repo root.
pkg_root_for() {
  local dir git_root
  dir=$(cd "$(dirname "$1")" 2>/dev/null && pwd) || return 1
  git_root=$(cd "$dir" && git rev-parse --show-toplevel 2>/dev/null) || return 1
  while :; do
    [ -d "$dir/node_modules/.bin" ] && { echo "$dir"; return 0; }
    [ "$dir" = "$git_root" ] && return 1
    dir=$(dirname "$dir")
  done
}

uses_typescript() {
  [ -f "$1/tsconfig.json" ] && [ -x "$1/node_modules/.bin/tsc" ]
}

main() {
  local f root out code
  f=$(read_file_path)
  [ -z "$f" ] && return 0
  is_ts_or_js "$f" || return 0
  root=$(pkg_root_for "$f") || return 0
  uses_typescript "$root" || return 0

  out=$(cd "$root" && node_modules/.bin/tsc --noEmit --pretty false 2>&1)
  code=$?
  if [ "$code" -ne 0 ]; then
    echo "$out" >&2
    exit 2
  fi
}

main
