#!/usr/bin/env python3
"""Screenshot one element and record it in the session's shots manifest.

Usage: shoot.py <shot|before|after> <name> <url> <selector> [--viewport 1280x800] [--note TEXT] [--bare] [--pad 24]

<selector> names the subject. The screenshot is of the subject's first ancestor that does
not sit flush with it (the subject plus its surroundings); --bare shoots the subject alone.
The target is cropped to the width of its visible content (text, images, and anything with a
background, border or shadow), then wrapped in --pad pixels of the page's background colour on
every side, so no edge of the image is flush with it; --pad 0 leaves a tight crop.

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

# Pick the target (the subject, or its first ancestor that does not sit flush with it),
# crop it to its visible content and wrap it in padding, then hide every sibling of the target and of its ancestors: the target moves to the top
# of the page, and fixed overlays (cookie banners, toolbars) go with them.
ISOLATE = """
(() => {
  const subject = document.querySelector(%s);
  if (!subject) return "missing";
  const flush = (a, b) => {
    const x = a.getBoundingClientRect(), y = b.getBoundingClientRect();
    return ["left", "top", "right", "bottom"].every((side) => Math.abs(x[side] - y[side]) <= 1);
  };
  let target = subject;
  if (%s)
    for (let n = subject.parentElement; n && n !== document.body; n = n.parentElement)
      if (!flush(n, subject)) { target = n; break; }
  const isPainted = (el) => {
    const style = getComputedStyle(el);
    return el.matches("img, svg, video, canvas, iframe")
      || style.backgroundColor !== "rgba(0, 0, 0, 0)"
      || style.backgroundImage !== "none"
      || style.boxShadow !== "none"
      || ["Top", "Right", "Bottom", "Left"].some((side) =>
        style["border" + side + "Style"] !== "none" && parseFloat(style["border" + side + "Width"]) > 0);
  };
  let contentRight = 0;
  const measure = (el) => {
    const style = getComputedStyle(el);
    if (style.display === "none" || style.visibility === "hidden") return;
    if (isPainted(el)) contentRight = Math.max(contentRight, el.getBoundingClientRect().right);
    for (const child of el.childNodes) {
      if (child.nodeType === Node.ELEMENT_NODE) measure(child);
      else if (child.nodeType === Node.TEXT_NODE && child.textContent.trim()) {
        const range = document.createRange();
        range.selectNodeContents(child);
        contentRight = Math.max(contentRight, range.getBoundingClientRect().right);
      }
    }
  };
  measure(target);
  const pad = %s;
  let background = "rgb(255, 255, 255)";
  for (let n = target; n; n = n.parentElement) {
    const color = getComputedStyle(n).backgroundColor;
    if (color !== "rgba(0, 0, 0, 0)" && color !== "transparent") { background = color; break; }
  }
  const width = Math.ceil(contentRight - target.getBoundingClientRect().left);
  const shot = document.createElement("div");
  shot.style.cssText = `box-sizing:content-box;width:${width}px;padding:${pad}px;background:${background}`;
  target.replaceWith(shot);
  shot.append(target);
  shot.setAttribute("data-shot-target", "");
  for (let n = shot; n && n !== document.body; n = n.parentElement)
    for (const s of n.parentElement.children) if (s !== n) s.style.display = "none";
  scrollTo(0, 0);
  return "ok";
})()
"""
TARGET = "[data-shot-target]"


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
    p.add_argument("--bare", action="store_true")
    p.add_argument("--pad", type=int, default=24)
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
    if "missing" in browser("eval", ISOLATE % (json.dumps(a.selector), json.dumps(not a.bare), a.pad)):
        sys.exit(f"selector not found at {a.url}: {a.selector}")
    browser("wait", "800")
    browser("screenshot", TARGET, str(image))

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
