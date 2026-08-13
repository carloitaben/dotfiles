#!/bin/bash
# Stop hook: tsc --noEmit for every TypeScript package in the repo, run once when
# Claude is about to finish the turn (not after every edit like the old PostToolUse
# hook — that was slow on big repos and flagged expected mid-edit type errors as
# broken). Checking the whole repo here is fine since Stop fires far less often,
# and it catches cross-package breakage a "just the touched package" check would miss.

INPUT=$(cat)
cwd=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)

git_root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || exit 0

errors=""
while IFS= read -r tsconfig; do
  root=$(dirname "$tsconfig")
  [ -x "$root/node_modules/.bin/tsc" ] || continue
  out=$(cd "$root" && node_modules/.bin/tsc --noEmit --pretty false 2>&1)
  if [ -n "$out" ]; then
    errors="${errors}${root}:
${out}

"
  fi
done < <(find "$git_root" -name tsconfig.json -not -path '*/node_modules/*')

if [ -n "$errors" ]; then
  jq -n --arg reason "$errors" '{decision: "block", reason: $reason}'
fi
