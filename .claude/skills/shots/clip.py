#!/usr/bin/env python3
"""Record a page load, and optionally one click, as a video in the session's shots manifest.

Usage:
  clip.py <clip|before|after> <name> <url> [--click TEXT] [--delay MS] [--seconds N] [--note TEXT]

`clip` records one video (entry kind "video", key `video`). `before` and `after` record the two
sides of a comparison (entry kind "video-comparison", keys `before`, `after`).

The recording starts on a blank page of the url's origin, then navigates to <url> as a hard load,
the way a user enters it. --click TEXT then clicks the first link, button, label or tab whose
text contains TEXT, after the page settles. --seconds N is how long to record after the load
and after the click (default 5). --delay MS holds every fetch/XHR response for MS (default 400)
so loading states last long enough to see; pass 0 to record at the real speed.

Writes ~/.claude/shots/$CLAUDE_CODE_SESSION_ID/<name>/<phase>.webm, a <phase>-sheet.png contact
sheet (4 frames per second) to read the video by, and upserts the entry in manifest.json.
Needs agent-browser, ffmpeg and node on PATH. An app behind a login: set AGENT_BROWSER_SESSION
and AGENT_BROWSER_RESTORE to the signed-in session first; the recording context starts without
the session's localStorage, so it is copied in after the recording starts.
"""
import argparse
import json
import os
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

HERE = Path(__file__).resolve().parent
LEAD_IN_SLACK = 0.2  # seconds of blank page kept before the navigation

CLICK = """(() => {
  const el = [...document.querySelectorAll("a, button, label, [role=tab]")]
    .find((e) => e.textContent.includes(%s));
  if (!el) return "missing";
  el.click();
  return "ok";
})()"""


def fail(msg):
    sys.exit(f"[clip] {msg}")


def ab(*args):
    r = subprocess.run(["agent-browser", *args], capture_output=True, text=True)
    if r.returncode:
        fail(f"agent-browser {' '.join(args)[:60]}: {(r.stderr or r.stdout).strip()}")
    return r.stdout.strip()


def evaluate(js):
    return json.loads(ab("eval", js))


def ffmpeg(*args):
    r = subprocess.run(["ffmpeg", "-v", "error", "-y", *args], capture_output=True, text=True)
    if r.returncode:
        fail(f"ffmpeg: {r.stderr.strip()}")


def duration(video):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(video)],
                         capture_output=True, text=True).stdout.strip()
    return float(out or 0)


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout.strip()


def record(url, click, delay, seconds, out):
    """Warm the page, then record a hard load of it. Returns the seconds of lead-in to trim."""
    origin = "{0.scheme}://{0.netloc}".format(urllib.parse.urlparse(url))
    # The warm-up pays the dev server's cold compile before the recording, and yields the
    # origin's localStorage (the login) to carry into the recording's fresh context.
    ab("open", url)
    ab("wait", "6000")
    storage = json.loads(evaluate("JSON.stringify({...localStorage})"))
    inject = "".join(f"localStorage.setItem({json.dumps(k)},{json.dumps(v)});" for k, v in storage.items())

    holder = None
    if delay:
        ws = next((l for l in ab("get", "cdp-url").splitlines() if l.startswith("ws://")), None)
        if not ws:
            fail("agent-browser get cdp-url printed no websocket url")
        holder = subprocess.Popen(["node", str(HERE / "delay.mjs"), ws, str(delay)], stdout=subprocess.PIPE, text=True)
        holder.stdout.readline()  # "delay up"
    try:
        ab("record", "start", str(out), f"{origin}/__clip_blank__")
        started = time.monotonic()
        evaluate(inject + "true")
        time.sleep(1)
        navigated = time.monotonic() - started
        ab("eval", f"location.href = {json.dumps(url)}")
        time.sleep(seconds)
        if click:
            if evaluate(CLICK % json.dumps(click)) == "missing":
                fail(f"nothing to click with text {click!r} at {url}")
            time.sleep(seconds)
        ab("record", "stop")
    finally:
        if holder:
            holder.terminate()
    return max(0.0, navigated - LEAD_IN_SLACK)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("phase", choices=["clip", "before", "after"])
    p.add_argument("name")
    p.add_argument("url")
    p.add_argument("--click")
    p.add_argument("--delay", type=int, default=400)
    p.add_argument("--seconds", type=float, default=5)
    p.add_argument("--note", default="")
    a = p.parse_args()

    session = os.environ.get("CLAUDE_CODE_SESSION_ID") or fail("CLAUDE_CODE_SESSION_ID is not set")
    root = Path.home() / ".claude" / "shots" / session
    manifest_path = root / "manifest.json"
    entries = json.loads(manifest_path.read_text()) if manifest_path.exists() else []
    kind = "video" if a.phase == "clip" else "video-comparison"
    entry = next((e for e in entries if e["name"] == a.name), None)
    if entry and entry["kind"] != kind:
        fail(f'"{a.name}" is already a {entry["kind"]}; pick another name')

    folder = root / a.name
    folder.mkdir(parents=True, exist_ok=True)
    raw, video = folder / f"{a.phase}-raw.webm", folder / f"{a.phase}.webm"
    ab("close")
    trim = record(a.url, a.click, a.delay, a.seconds, raw)
    ffmpeg("-ss", f"{trim:.2f}", "-i", str(raw), "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32", str(video))
    print(f"[clip] recorded {duration(raw):.1f}s, trimmed {trim:.1f}s lead-in -> {duration(video):.1f}s", file=sys.stderr)
    raw.unlink()
    sheet = folder / f"{a.phase}-sheet.png"
    ffmpeg("-i", str(video), "-vf", "fps=4,scale=200:-1,tile=8x6", "-frames:v", "1", str(sheet))

    key = "video" if a.phase == "clip" else a.phase
    if entry is None:
        entry = {"name": a.name, "kind": kind}
        entries.append(entry)
    entry.update(url=a.url, delay=a.delay, **{key: str(video)})
    if a.click:
        entry["click"] = a.click
    if a.note:
        entry["note"] = a.note
    entry.setdefault("note", "")
    if a.phase != "before":
        entry["head_sha"] = git("rev-parse", "HEAD")
    manifest_path.write_text(json.dumps(entries, indent=2) + "\n")
    print(video)
    print(sheet)


main()
