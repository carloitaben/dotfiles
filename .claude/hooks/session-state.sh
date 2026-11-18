#!/bin/bash
# Claude hook. Tracks sessions in ~/.claude/live-sessions/<id>.json so `cr` can
# resume the ones whose process died (cmd-w, quit, logoff).
#   start: register (overwrites on resume, so the new pid replaces the dead one)
#   touch: heartbeat, bumps mtime
#   end:   forget when deliberately left (exit, /clear, /resume to another)
dir=~/.claude/live-sessions
mkdir -p "$dir"
input="$(cat)"
sid="$(jq -r '.session_id' <<<"$input")"
file="$dir/$sid.json"

# TEMP: log events to learn SessionEnd reasons. Remove once confirmed.
echo "$(date +%T) $1 $(jq -c . <<<"$input")" >> ~/.claude/session-events.log

case "$1" in
  start)
    jq -n --arg cwd "$(jq -r '.cwd' <<<"$input")" --argjson pid "$PPID" \
      --arg lstart "$(ps -o lstart= -p "$PPID")" \
      '{cwd: $cwd, pid: $pid, lstart: $lstart}' > "$file" ;;
  touch) [ -f "$file" ] && touch "$file" ;;
  end)
    case "$(jq -r '.reason' <<<"$input")" in
      prompt_input_exit|clear|resume) rm -f "$file" ;;
    esac ;;
esac
exit 0
