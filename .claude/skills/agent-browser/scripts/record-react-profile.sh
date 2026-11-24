#!/usr/bin/env bash
# Records a React DevTools Profiler trace of focusing a field, typing text into
# it (if given), then blurring it,
# in the real Chrome (it has the React DevTools extension), saves the export to
# the Desktop, and prints the parsed summary.
#
# Usage: record-react-profile.sh <url> [field-label] [text-to-type]
#
# Drives Chrome with physical input (agent-desktop --headed). It takes focus and
# moves the cursor for about 40s, so ask the user to keep hands off.
#
# Opens its own Chrome window and closes it afterwards.
#
# Needs: agent-desktop with Accessibility granted, Chrome with the React DevTools
# extension, the page already logged in in Chrome, and Chrome's download folder
# set to the Desktop (macOS blocks reading ~/Downloads).
set -euo pipefail

URL="${1:?usage: record-react-profile.sh <url> [field-label] [text-to-type]}"
FIELD="${2:-Title}"  # accessible name of the textfield to focus
TEXT="${3:-}"        # typed one key at a time before blurring
DESKTOP="$HOME/Desktop"
PARSER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/parse-devtools-profile.py"
APP="Google Chrome"

die() { echo "error: $*" >&2; exit 1; }

# Reads a JSON envelope on stdin, runs the python body with `d` bound to it.
json() { python3 -I -c "import sys,json; d=json.load(sys.stdin)
$1"; }

ad() { agent-desktop "$@"; }

click() { ad click "$1" --headed | json "sys.exit(0 if d['ok'] else d['error']['code'])" ; }

# Prints the ref of the first element matching role and name (substring).
find_ref() {
  ad find --app "$APP" --window-id "$WINDOW" --role "$1" --name "$2" --timeout-ms 15000 |
    json "m=d['data']['matches']
print(m[0]['ref_id'] if m else '')"
}

wait_for_ref() {
  local ref=""
  for _ in $(seq 1 20); do
    ref=$(find_ref "$1" "$2")
    [ -n "$ref" ] && { echo "$ref"; return; }
    sleep 1
  done
  die "timed out waiting for $1 '$2'"
}

# Chrome window ids, largest first.
chrome_windows() {
  ad list-windows --app "$APP" | json "
ws=[w for w in d['data'] if w.get('bounds')]
ws.sort(key=lambda w: w['bounds']['width']*w['bounds']['height'], reverse=True)
print(' '.join(w['id'] for w in ws))"
}

# Work in a new window of its own, so there are no tabs to find or close.
BEFORE=$(chrome_windows)
ad focus-window --window-id "${BEFORE%% *}" >/dev/null
ad press cmd+n --headed >/dev/null
WINDOW=""
for _ in $(seq 1 10); do
  sleep 1
  for id in $(chrome_windows); do
    case " $BEFORE " in *" $id "*) ;; *) WINDOW=$id; break ;; esac
  done
  [ -n "$WINDOW" ] && break
done
[ -n "$WINDOW" ] || die "no new Chrome window appeared"

echo "Chrome window $WINDOW: opening $URL"
sleep 1
# Chrome autocompletes the omnibox, so set-value reports an unverified result even on success.
ad set-value "$(wait_for_ref textfield 'Address and search bar')" "$URL" >/dev/null || true
ad press return --headed >/dev/null
wait_for_ref textfield "$FIELD" >/dev/null

echo "Opening DevTools, Profiler"
ad press cmd+alt+i --headed >/dev/null
click "$(wait_for_ref radiobutton 'Profiler')"
sleep 2

# The profiler toolbar buttons have no accessible names. Order: Record, Reload,
# Clear, [Choose File input], Load, Save. Anchor on the input.
toolbar() {
  ad snapshot --app "$APP" --window-id "$WINDOW" -i --compact --timeout-ms 20000 |
    json "
import re
refs={}
def walk(n):
    r=n.get('ref_id')
    if r: refs[r]=n
    for c in n.get('children',[]): walk(c)
walk(d['data']['tree'])
anchor=next(r for r,n in refs.items() if (n.get('name') or '').startswith('Choose File'))
snap,num=anchor.rsplit(':e',1)
print(f'{snap}:e{int(num)+$1}')"
}

echo "Recording"
click "$(toolbar -3)"
wait_for_ref button 'Stop recording' >/dev/null

click "$(wait_for_ref textfield "$FIELD")"
sleep 1
for ((i = 0; i < ${#TEXT}; i++)); do
  ad press "${TEXT:i:1}" --headed >/dev/null
  sleep 0.3
done
# Blur by clicking empty space to the right of the page heading.
H=$(ad find --app "$APP" --window-id "$WINDOW" --role heading --timeout-ms 15000 | json "
for m in d['data']['matches']:
    b=m.get('bounds')
    if b and 'webarea:DevTools' not in m['path'] and b['x']>600: print(f\"{int(b['x']+b['width']-20)},{int(b['y']+b['height']/2)}\"); break")
[ -n "$H" ] || die "could not find the page heading to click"
ad mouse-click --xy "$H" --headed >/dev/null
sleep 1

DIRTY=$(ad find --app "$APP" --window-id "$WINDOW" --text "Unsaved changes" --count --timeout-ms 8000 | json "print(d['data']['count'])")
[ "$DIRTY" = "0" ] || echo "note: the form turned dirty after focus and blur"

echo "Stopping"
click "$(wait_for_ref button 'Stop recording')"
sleep 3

echo "Saving"
BEFORE=$(ls -t "$DESKTOP"/profiling-data*.json 2>/dev/null | head -1 || true)
NEWEST=""
for _ in 1 2 3 4; do
  # The first click after a recording sometimes does nothing, so retry.
  click "$(toolbar 2)" || true
  sleep 3
  NEWEST=$(ls -t "$DESKTOP"/profiling-data*.json 2>/dev/null | head -1 || true)
  [ -n "$NEWEST" ] && [ "$NEWEST" != "$BEFORE" ] && break
  NEWEST=""
done
[ -n "$NEWEST" ] || die "no new profiling-data*.json on Desktop; is Chrome's download folder Desktop?"

# Close our window. The page has a beforeunload handler, so Chrome asks
# "Leave site?" in a prompt the accessibility tree doesn't expose: confirm it
# with Return, but only while the window is still open, or Return would hit
# whatever is focused next.
window_open() { case " $(chrome_windows) " in *" $WINDOW "*) return 0 ;; *) return 1 ;; esac; }
ad focus-window --window-id "$WINDOW" >/dev/null
ad press cmd+alt+i --headed >/dev/null
sleep 1
ad press cmd+w --headed >/dev/null
sleep 1.5
if window_open; then
  ad press return --headed >/dev/null
  sleep 1.5
fi
! window_open || echo "warning: could not close the Chrome window $WINDOW"

echo "Saved $NEWEST"
python3 -I "$PARSER" "$NEWEST"
