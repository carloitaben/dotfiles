#!/usr/bin/env python3
"""Summarize React DevTools Profiler exports, per commit.

Usage: parse-devtools-profile.py PROFILE [PROFILE ...]

PROFILE is the exported .json or the .zip macOS makes of it. Prints, per
commit: fibers rendered, duration, who scheduled the update (updaters), and the
most-rendered component names. Pass a "before" and an "after" export to compare.
"""
import json
import sys
import zipfile
from collections import Counter


def load(path):
    if path.endswith(".zip"):
        with zipfile.ZipFile(path) as z:
            name = next(n for n in z.namelist() if n.endswith(".json") and not n.startswith("__MACOSX"))
            return json.loads(z.read(name))
    with open(path) as f:
        return json.load(f)


def summarize(path):
    data = load(path)
    print(f"== {path}")
    for root in data["dataForRoots"]:
        names = {s[0]: (s[1] or {}).get("displayName") or f"?{s[0]}" for s in root["snapshots"]}
        total_fibers = total_ms = 0
        for i, commit in enumerate(root["commitData"]):
            fibers = commit["fiberActualDurations"]
            counts = Counter(names.get(fid, f"?{fid}") for fid, _ in fibers)
            updaters = sorted({u.get("displayName") or "?" for u in commit["updaters"] or []})
            print(f"commit {i}: {len(fibers)} fibers, {commit['duration']}ms, updaters={updaters}")
            print(f"  top: {counts.most_common(8)}")
            total_fibers += len(fibers)
            total_ms += commit["duration"]
        print(f"total: {len(root['commitData'])} commits, {total_fibers} fibers, {total_ms:.1f}ms")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for p in sys.argv[1:]:
        summarize(p)
