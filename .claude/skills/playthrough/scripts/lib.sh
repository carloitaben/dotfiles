#!/bin/bash
# Source from a flow script:  source ~/.claude/skills/playthrough/scripts/lib.sh
#   SESSION=name FRAMES=/path/to/frames   (set before sourcing)
# Gives: ab, caption "text", shot <seconds>
SESSION=${SESSION:-playthrough}
FRAMES=${FRAMES:?set FRAMES to the frames directory}
mkdir -p "$FRAMES"
_N=$(ls "$FRAMES"/f*.png 2>/dev/null | wc -l | tr -d ' ')

ab() { agent-browser --session "$SESSION" "$@" 2>&1; }

# Fixed banner at the bottom of the page. Lives in the DOM, so it survives
# in-app navigation but not a full reload: call it again after one.
caption() {
  local text
  text=$(printf '%s' "$1" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')
  ab eval "(()=>{let b=document.getElementById('__cap');if(!b){b=document.createElement('div');b.id='__cap';b.style.cssText='position:fixed;bottom:28px;left:50%;transform:translateX(-50%);z-index:2147483647;background:#111;color:#fff;font:600 20px/1.3 Inter,system-ui,sans-serif;padding:14px 22px;border-radius:10px;box-shadow:0 4px 18px rgba(0,0,0,.35);max-width:1150px;text-align:center';document.body.appendChild(b)}b.textContent=$text;return 1})()" >/dev/null
}

# Screenshot the active tab as the next frame, shown for <seconds> in the video.
shot() {
  _N=$((_N + 1))
  local f="$FRAMES/f$(printf %02d $_N)"
  ab screenshot "$f.png" >/dev/null
  echo "${1:-2.5}" > "$f.dur"
}
