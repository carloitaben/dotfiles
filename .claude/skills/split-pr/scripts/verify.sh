#!/usr/bin/env bash
# Per-branch size table + losslessness overlay. Semantics: SKILL.md step 4.
#
#   verify.sh <base> <snap> <branch>[@<parent>] ...
#   verify.sh origin/develop refs/split/snap \
#     feat/plb  feat/schema  feat/api@feat/schema  feat/ui@feat/api
set -euo pipefail

[ $# -ge 3 ] || { sed -n '3,6p' "$0" | cut -c3-; exit 2; }
base=$1 snap=$2
shift 2

idx=$(mktemp -u)
seen=$(mktemp)
trap 'rm -f "$idx" "$idx.lock" "$seen"' EXIT
export GIT_INDEX_FILE=$idx
git read-tree "$base"

printf '%-52s %6s %8s %8s\n' branch files added removed
status=0
for spec in "$@"; do
  branch=${spec%%@*}
  parent=$base
  [ "$spec" != "$branch" ] && parent=${spec#*@}

  git diff --numstat "$parent" "$branch" | awk -v b="$branch" '
    { f++; if ($1 != "-") { a += $1; d += $2 } }
    END { printf "%-52s %6d %8d %8d\n", b, f, a, d }'

  git diff --raw --no-renames "$parent" "$branch" | while read -r _ mode _ blob _ path; do
    if [ "$blob" = 0000000000000000000000000000000000000000 ]; then
      git update-index --force-remove -- "$path"
    else
      # --raw prints abbreviated blobs; resolve to full ones.
      full=$(git rev-parse "$branch:$path")
      git update-index --add --cacheinfo "$mode,$full,$path"
      echo "$path $full $branch" >>"$seen"
    fi
  done
done

# Same path, different content, branches not stacked on one another.
sort -u "$seen" | awk '{ print $1, $2 }' | uniq | awk '{ n[$1]++ } END { for (p in n) if (n[p] > 1) print p }' |
  while read -r path; do
    set -- $(grep "^$path " "$seen" | awk '{ print $3 }')
    for x in "$@"; do
      for y in "$@"; do
        [ "$x" \< "$y" ] || continue
        if ! git merge-base --is-ancestor "$x" "$y" && ! git merge-base --is-ancestor "$y" "$x"; then
          echo "⚠ $path differs between $x and $y (parallel branches must carry identical content)"
        fi
      done
    done
  done

overlay=$(git write-tree)
echo
if [ "$(git rev-parse "$snap^{tree}")" = "$overlay" ]; then
  echo "✓ lossless: overlay of all branches == $snap"
else
  echo "✗ NOT lossless: overlay differs from $snap"
  git diff --stat "$snap" "$overlay" -- 2>/dev/null || git diff-tree --stat "$snap^{tree}" "$overlay"
  status=1
fi
exit $status
