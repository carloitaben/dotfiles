#!/bin/bash
# Usage: frames-to-mp4.sh <out.mp4> <frames-dir> [<frames-dir>...]
# A frames dir holds fNN.png (sorted order) and an fNN.dur beside each one with
# the seconds to show it. Several dirs are joined in order (e.g. before, after).
set -e
[ $# -ge 2 ] || { echo "usage: $0 <out.mp4> <frames-dir>..." >&2; exit 1; }
OUT=$1; shift
FPS=15
TMP=$(mktemp -d)
N=0
for DIR in "$@"; do
  for F in $(ls "$DIR"/f*.png | sort); do
    COPIES=$(python3 -c "print(max(1, round($(cat "${F%.png}.dur") * $FPS)))")
    for _ in $(seq 1 "$COPIES"); do
      N=$((N + 1))
      ln "$F" "$TMP/$(printf %06d $N).png"
    done
  done
done
ffmpeg -loglevel error -y -framerate $FPS -i "$TMP/%06d.png" \
  -vf "scale=1280:720,format=yuv420p" -c:v libx264 -crf 20 \
  -movflags +faststart "$OUT"
rm -rf "$TMP"
echo "$OUT"
