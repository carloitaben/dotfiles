#!/usr/bin/env python3
"""Screenshot a page or one element and record it in the session's shots manifest.

Usage:
  shoot.py <shot|before|after> <name> <url> --scope page    [--device desktop|mobile] [--full] [--zoom N] [--note TEXT]
  shoot.py <shot|before|after> <name> <url> <selector> --scope element [--device desktop|mobile] [--note TEXT] [--bare] [--pad 24]

--scope page: the viewport as the user sees it, app chrome included. --full captures the whole
page height instead of the viewport. --zoom N scales the page (0.8 fits more into the frame).
No selector.

--scope element: <selector> names the subject. The screenshot is of the subject's first ancestor
that does not sit flush with it (the subject plus its surroundings); --bare shoots the subject
alone. The target is cropped to the width of its visible content (text, images, and anything
with a background, border or shadow), then wrapped in --pad pixels of the page's background
colour on every side, so no edge of the image is flush with it; --pad 0 leaves a tight crop.

--device desktop: MacBook Pro 14", 1512x982 CSS px at 2x (default).
--device mobile: iPhone 16 Pro, 402x874 CSS px at 3x, touch and mobile user agent.

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
  // A target taller than the viewport and 3x its subject is a page wrapper, not surroundings.
  const wrapper = target !== subject && target.getBoundingClientRect().height > innerHeight
    && target.getBoundingClientRect().height > 3 * subject.getBoundingClientRect().height;
  if (wrapper) return "wrapper";
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
  return "ok " + Math.ceil(shot.getBoundingClientRect().height);
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


def open_with_device(url, device, emulation):
    """Open `url` in a fresh browser at the device's size, and fail if the size did not stick.

    Device emulation (user agent, touch) does not unset, so each shot starts a fresh browser.
    `set device` needs a launched browser, so the page opens, the emulation is set, and the page
    opens again to load under it. The size is read back to be sure.
    """
    width, height = (int(v) for v in DEVICES[device][0].split("@")[0].split("x"))
    scale = int(DEVICES[device][0].split("@")[1])
    for _ in range(3):
        subprocess.run(["agent-browser", "close"], capture_output=True)
        browser("open", url)
        browser(*emulation)
        browser("open", url)
        got = json.loads(json.loads(browser("eval", "JSON.stringify([innerWidth, innerHeight, devicePixelRatio])")))
        if got == [width, height, scale]:
            return
    sys.exit(f"{device} emulation did not apply: wanted {[width, height, scale]}, got {got}")


DEVICES = {
    "desktop": ("1512x982@2", ["set", "viewport", "1512", "982", "2"]),
    "mobile": ("402x874@3", ["set", "device", "iPhone 16 Pro"]),
}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("phase", choices=["shot", "before", "after"])
    p.add_argument("name")
    p.add_argument("url")
    p.add_argument("selector", nargs="?")
    p.add_argument("--scope", choices=["page", "element"], required=True)
    p.add_argument("--device", choices=list(DEVICES), default="desktop")
    p.add_argument("--full", action="store_true")
    p.add_argument("--zoom", type=float, default=1.0)
    p.add_argument("--note", default="")
    p.add_argument("--bare", action="store_true")
    p.add_argument("--pad", type=int, default=24)
    a = p.parse_args()

    if a.scope == "element" and not a.selector:
        sys.exit("--scope element needs a selector")
    if a.scope == "page" and (a.selector or a.bare):
        sys.exit("--scope page takes no selector; use --scope element to shoot a component")
    if a.scope == "element" and (a.full or a.zoom != 1.0):
        sys.exit("--full and --zoom apply to --scope page")

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

    viewport, emulation = DEVICES[a.device]
    open_with_device(a.url, a.device, emulation)
    browser("wait", "2500")
    if a.scope == "element":
        isolated = browser("eval", ISOLATE % (json.dumps(a.selector), json.dumps(not a.bare), a.pad))
        if "missing" in isolated:
            sys.exit(f"selector not found at {a.url}: {a.selector}")
        if "wrapper" in isolated:
            sys.exit(f"{a.selector} sits flush in a page-tall wrapper, so its surroundings are the whole page: add --bare")
        # An element screenshot paints only what fits the viewport, so grow the frame to the target.
        width, height = (int(v) for v in viewport.split("@")[0].split("x"))
        target_height = int(isolated.strip('"').split()[-1])
        # Lazy media settles after the resize and grows the target: measure again until it fits.
        for _ in range(4):
            if target_height <= height:
                break
            height = target_height + 400  # slack: paint stops short of an exactly-fitting frame
            browser("set", "viewport", str(width), str(height), viewport.split("@")[1])
            browser("wait", "2000")
            target_height = int(float(json.loads(browser("eval", f'JSON.stringify(Math.ceil(document.querySelector("{TARGET}").getBoundingClientRect().height))'))))
        browser("wait", "800")
        browser("screenshot", TARGET, str(image))
    else:
        if a.zoom != 1.0:
            browser("eval", f"document.documentElement.style.zoom = {a.zoom}")
            browser("wait", "800")
        browser("screenshot", *(["--full"] if a.full else []), str(image))

    key = "image" if a.phase == "shot" else a.phase
    if entry is None:
        entry = {"name": a.name, "kind": kind}
        entries.append(entry)
    entry.update(url=a.url, scope=a.scope, device=a.device, viewport=viewport, **{key: str(image)})
    if a.selector:
        entry["selector"] = a.selector
    if a.scope == "page":
        entry.update(full=a.full, zoom=a.zoom)
    if a.note:
        entry["note"] = a.note
    entry.setdefault("note", "")
    if a.phase != "before":
        entry["head_sha"] = git("rev-parse", "HEAD")
    manifest_path.write_text(json.dumps(entries, indent=2) + "\n")
    print(image)


main()
