#!/usr/bin/env python3
"""Screenshot one element and record it in the session's shots manifest.

Usage: shoot.py <shot|before|after> <name> <url> <selector> [--viewport 1280x800] [--note TEXT]

Writes ~/.claude/shots/$CLAUDE_CODE_SESSION_ID/<name>/<phase>.png and upserts the
entry for <name> in manifest.json next to it. Needs agent-browser on PATH.

`shot` records a single screenshot (entry kind "shot", key `image`). `before` and `after`
record a comparison (entry kind "comparison", keys `before` and `after`).
"""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

# Hide every sibling of the target and of its ancestors: the target moves to the top
# of the page, and fixed overlays (cookie banners, toolbars) go with them.
ISOLATE = """
(() => {
  const target = document.querySelector(%s);
  if (!target) return "missing";
  for (let n = target; n && n !== document.body; n = n.parentElement)
    for (const s of n.parentElement.children) if (s !== n) s.style.display = "none";
  scrollTo(0, 0);
  return "ok";
})()
"""


def browser(*args):
    r = subprocess.run(["agent-browser", *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"agent-browser {' '.join(args)[:60]}: {(r.stderr or r.stdout).strip()}")
    return r.stdout.strip()


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout.strip()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("phase", choices=["shot", "before", "after"])
    p.add_argument("name")
    p.add_argument("url")
    p.add_argument("selector")
    p.add_argument("--viewport", default="1280x800")
    p.add_argument("--note", default="")
    a = p.parse_args()

    session = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not session:
        sys.exit("CLAUDE_CODE_SESSION_ID is not set")
    root = Path.home() / ".claude" / "shots" / session
    manifest_path = root / "manifest.json"
    entries = json.loads(manifest_path.read_text()) if manifest_path.exists() else []
    kind = "shot" if a.phase == "shot" else "comparison"
    entry = next((e for e in entries if e["name"] == a.name), None)
    if entry and entry["kind"] != kind:
        sys.exit(f'"{a.name}" is already a {entry["kind"]}; pick another name')

    image = root / a.name / f"{a.phase}.png"
    image.parent.mkdir(parents=True, exist_ok=True)

    width, height = a.viewport.split("x")
    browser("set", "viewport", width, height)
    browser("open", a.url)
    browser("wait", "2500")
    if "missing" in browser("eval", ISOLATE % json.dumps(a.selector)):
        sys.exit(f"selector not found at {a.url}: {a.selector}")
    browser("wait", "800")
    browser("screenshot", a.selector, str(image))

    key = "image" if a.phase == "shot" else a.phase
    if entry is None:
        entry = {"name": a.name, "kind": kind}
        entries.append(entry)
    entry.update(url=a.url, selector=a.selector, viewport=a.viewport, **{key: str(image)})
    if a.note:
        entry["note"] = a.note
    entry.setdefault("note", "")
    if a.phase != "before":
        entry["head_sha"] = git("rev-parse", "HEAD")
    manifest_path.write_text(json.dumps(entries, indent=2) + "\n")
    print(image)


main()
