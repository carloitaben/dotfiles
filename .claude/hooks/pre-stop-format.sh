#!/bin/bash
# Stop hook: prettier --write + eslint --fix over every file git sees as changed
# (staged, unstaged, or untracked) in the repo, once when Claude finishes the
# turn — instead of after every single edit, which rewrote files out from under
# Claude's own in-progress patches. Uses git status as the "what did we touch"
# signal instead of a separate tracking hook.

INPUT=$(cat)
cwd=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)

git_root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || exit 0

is_formattable() {
  case "$1" in
    *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md|*.mdx|*.html|*.yaml|*.yml) return 0 ;;
    *) return 1 ;;
  esac
}

# Nearest ancestor (up to the git root) that has its own node_modules/.bin —
# handles pnpm/yarn workspaces where each app/package has its own toolchain.
pkg_root_for() {
  local dir
  dir=$(cd "$(dirname "$1")" 2>/dev/null && pwd) || return 1
  while :; do
    [ -d "$dir/node_modules/.bin" ] && { echo "$dir"; return 0; }
    [ "$dir" = "$git_root" ] && return 1
    dir=$(dirname "$dir")
  done
}

changed_files() {
  cd "$git_root" || return 1
  { git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u
}

while IFS= read -r f; do
  [ -z "$f" ] && continue
  abs="$git_root/$f"
  [ -f "$abs" ] || continue
  is_formattable "$abs" || continue
  root=$(pkg_root_for "$abs") || continue

  [ -x "$root/node_modules/.bin/prettier" ] && "$root/node_modules/.bin/prettier" --write "$abs" 2>/dev/null

  case "$abs" in
    *.ts|*.tsx)
      [ -x "$root/node_modules/.bin/eslint" ] && "$root/node_modules/.bin/eslint" --fix "$abs" 2>/dev/null
      ;;
  esac
done < <(changed_files)

exit 0
