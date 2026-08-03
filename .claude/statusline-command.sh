#!/bin/bash
# Claude Code statusline: context tokens (k)

input=$(cat)

tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')

tokens_k=$(awk -v t="$tokens" 'BEGIN { printf "%.1fk", t/1000 }')

printf '\033[2m%s tokens\033[0m' "$tokens_k"
