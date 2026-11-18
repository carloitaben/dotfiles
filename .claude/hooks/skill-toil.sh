#!/bin/bash
# Claude hook. Nudges toil reporting when a skill run piles up Bash calls.
#   start: a skill began. Typed /skill (UserPromptExpansion) always starts a fresh
#          run; a Skill-tool call only starts one when none is active, so a skill
#          loading another skill does not reset its caller's count.
#   count: PostToolUse Bash. Counts per agent (subagents have their own count);
#          at THRESHOLD, injects one non-forcing nudge per agent per run.
# State: ~/.claude/skill-toil/<session_id>.json. Swept after 7 days.
THRESHOLD=10
dir=~/.claude/skill-toil
mkdir -p "$dir"
input="$(cat)"
file="$dir/$(jq -r '.session_id' <<<"$input").json"

case "$1" in
  start)
    if [ "$(jq -r '.hook_event_name' <<<"$input")" = UserPromptExpansion ]; then
      skill="$(jq -r '.command_name // empty' <<<"$input")"
    else
      skill="$(jq -r '.tool_input.skill // empty' <<<"$input")"
      [ -f "$file" ] && exit 0
    fi
    [ -z "$skill" ] && exit 0
    jq -n --arg skill "$skill" '{skill: $skill, counts: {}, nudged: {}}' > "$file"
    find "$dir" -name '*.json' -mtime +7 -delete 2>/dev/null ;;
  count)
    [ -f "$file" ] || exit 0
    agent="$(jq -r '.agent_id // "session"' <<<"$input")"
    state="$(jq --arg a "$agent" '.counts[$a] += 1' "$file")"
    count="$(jq -r --arg a "$agent" '.counts[$a]' <<<"$state")"
    if [ "$count" -ge "$THRESHOLD" ] && [ "$(jq -r --arg a "$agent" '.nudged[$a] // false' <<<"$state")" = false ]; then
      state="$(jq --arg a "$agent" '.nudged[$a] = true' <<<"$state")"
      who="this session"; [ "$agent" != session ] && who="this subagent"
      jq -n --arg msg "Skill toil check: /$(jq -r .skill <<<"$state") has used $count Bash calls in $who. If some were mechanical steps a script could do, apply the Skill toil rule in CLAUDE.md." \
        '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $msg}}'
    fi
    echo "$state" > "$file.tmp" && mv "$file.tmp" "$file" ;;
esac
exit 0
