#!/bin/sh
f="$HOME/.config/lazygit/github_pull_requests.json"
mkdir -p "$(dirname "$f")"
[ -f "$f" ] || echo '{}' > "$f"
jq -r --arg repo "$(git rev-parse --show-toplevel)" '.[$repo] // [] | .[] | select(.state == "OPEN" or .state == "DRAFT") | "#\(.number): \(.title) - \(.headRefName)"' "$f"
