#!/usr/bin/env python3
"""Upload images to GitHub through a PR's comment box, then clear the box.

Usage: upload.py <pr-url> <image>...   (png or jpg)

Prints a JSON object {image path: github.com/user-attachments URL} on stdout.
Progress goes to stderr. Nothing is ever posted: the draft is cleared at the end.

Each image goes on the clipboard and is pasted into the comment box, which GitHub
uploads like a drag-and-drop. Drives the real keyboard through agent-desktop (macOS).
Before every physical input the PR window is brought to front and focus is confirmed,
but do not type or click while it runs. A text clipboard is restored afterwards.
"""
import json
import os
import re
import subprocess
import sys
import time

TEXTAREA = "Markdown value"
IMG_URL = re.compile(r'<img [^>]*src="(https://github\.com/user-attachments/assets/[^"]+)"')
CLIPBOARD_CLASS = {".png": "PNGf", ".jpg": "JPEG", ".jpeg": "JPEG"}

# (app, window title fragment) of the PR page; set once in main().
TARGET = None


def log(msg):
    print(f"[pr-proof] {msg}", file=sys.stderr)


def fail(msg):
    sys.exit(f"[pr-proof] {msg}")


def desktop(*args, check=True):
    t0 = time.time()
    out = subprocess.run(["agent-desktop", *args], capture_output=True, text=True)
    if os.environ.get("PR_PROOF_TIMING"):
        log(f"{time.time() - t0:5.2f}s agent-desktop {' '.join(args)[:70]}")
    try:
        result = json.loads(out.stdout)
    except json.JSONDecodeError:
        fail(f"agent-desktop {' '.join(args)}: {out.stdout or out.stderr}")
    if check and not result["ok"]:
        fail(f"agent-desktop {' '.join(args)}: {result['error']['message']}")
    return result


def refocus():
    """Bring the PR window to front and confirm OS focus. Call before any physical input,
    so a window the user switched to meanwhile never receives the keys."""
    app, title = TARGET
    if not desktop("focus-window", "--app", app, "--title", title, check=False)["ok"]:
        desktop("focus-window", "--app", app)


def press(key):
    refocus()
    desktop("press", key)


def find(app, name):
    result = desktop("find", "--app", app, "--name", name, check=False)
    return result["data"]["matches"] if result["ok"] else []


def wait_for(what, probe, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        found = probe()
        if found:
            return found
        time.sleep(0.1)
    fail(f"timed out waiting for {what}")


def default_browser():
    """Path of the app macOS opens https links with."""
    script = 'ObjC.import("AppKit"); $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("https://github.com")).path.js'
    out = subprocess.run(["osascript", "-l", "JavaScript", "-e", script], capture_output=True, text=True)
    if out.returncode != 0 or not out.stdout.strip():
        fail("could not find the default browser")
    return out.stdout.strip()


def textarea(app):
    matches = find(app, TEXTAREA)
    return matches[-1] if matches else None


def draft_urls(app):
    """Upload URLs currently in the comment box, in order."""
    box = textarea(app)
    return IMG_URL.findall(box.get("value") or "") if box else []


def set_clipboard_image(path):
    kind = CLIPBOARD_CLASS[os.path.splitext(path)[1].lower()]
    script = f'set the clipboard to (read (POSIX file "{path}") as «class {kind}»)'
    out = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if out.returncode != 0:
        fail(f"could not put {path} on the clipboard: {out.stderr.strip()}")


def paste_image(app, image):
    """Paste one image into the comment box; returns its new upload URL."""
    known = set(draft_urls(app))
    set_clipboard_image(image)
    box = wait_for("the comment box", lambda: textarea(app))
    refocus()
    desktop("--headed", "focus", box["ref_id"])
    press("cmd+v")

    def uploaded():
        fresh = [url for url in draft_urls(app) if url not in known]
        return fresh[0] if fresh else None

    return wait_for(f"{os.path.basename(image)} to upload", uploaded, timeout=90)


def clear_draft(app):
    """Real key events, so GitHub's persisted draft is cleared too."""
    box = textarea(app)
    if not box:
        return
    refocus()
    desktop("--headed", "focus", box["ref_id"])
    press("cmd+a")
    press("delete")
    wait_for("the comment box to empty", lambda: not (textarea(app) or {}).get("value"), timeout=5)


def main():
    global TARGET
    if len(sys.argv) < 3:
        fail("usage: upload.py <pr-url> <image>...")
    pr_url, images = sys.argv[1], [os.path.abspath(p) for p in sys.argv[2:]]
    for image in images:
        if not os.path.isfile(image):
            fail(f"not a file: {image}")
        if os.path.splitext(image)[1].lower() not in CLIPBOARD_CLASS:
            fail(f"only png and jpg are supported: {image}")

    saved_clipboard = subprocess.run(["pbpaste"], capture_output=True, text=True).stdout

    log("driving the keyboard: hands off until it finishes")
    browser = default_browser()
    app = os.path.basename(browser).removesuffix(".app")
    subprocess.run(["open", "-a", browser, pr_url], check=True)
    log(f"browser: {app}")
    number = pr_url.rstrip("/").rsplit("/", 1)[-1]
    TARGET = (app, f"Pull Request #{number}")
    wait_for("the PR comment box", lambda: textarea(app), timeout=45)

    try:
        urls = {image: paste_image(app, image) for image in images}
    finally:
        clear_draft(app)
        subprocess.run(["pbcopy"], input=saved_clipboard, text=True)
    print(json.dumps(urls, indent=2))


main()
