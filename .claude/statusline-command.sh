#!/bin/bash
# Claude Code statusline: context tokens (k) + rate limits (5h/7d)

input=$(cat)

tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
tokens_k=$(awk -v t="$tokens" 'BEGIN { printf "%.1fk", t/1000 }')

five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

limits=""
[ -n "$five" ] && limits="$(printf '%.0f' "$five")% 5h"
[ -n "$week" ] && limits="${limits:+$limits | }$(printf '%.0f' "$week")% 7d"

out="${tokens_k} tokens"
[ -n "$limits" ] && out="${limits} | ${out}"

printf '\033[2m%s\033[0m' "$out"
