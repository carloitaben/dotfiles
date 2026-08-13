#!/bin/bash
# PostToolUse hook for Edit|Write|MultiEdit: prettier --write + eslint --fix, scoped to the edited file.

read_file_path() {
  jq -r '.tool_input.file_path // .tool_response.filePath // empty'
}

is_formattable() {
  case "$1" in
    *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md|*.mdx|*.html|*.yaml|*.yml) return 0 ;;
    *) return 1 ;;
  esac
}

# Nearest ancestor (up to the git root) that has its own node_modules/.bin —
# handles pnpm/yarn workspaces where each app/package has its own toolchain
# instead of a single one at the repo root.
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

main() {
  local f root
  f=$(read_file_path)
  [ -z "$f" ] && return 0
  is_formattable "$f" || return 0
  root=$(pkg_root_for "$f") || return 0

  [ -x "$root/node_modules/.bin/prettier" ] && "$root/node_modules/.bin/prettier" --write "$f"

  case "$f" in
    *.ts|*.tsx)
      [ -x "$root/node_modules/.bin/eslint" ] && "$root/node_modules/.bin/eslint" --fix "$f"
      ;;
  esac
}

main 2>/dev/null || true
