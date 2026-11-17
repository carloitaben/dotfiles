#!/usr/bin/env python3
"""Upload images to GitHub through a PR's comment box, then clear the box.

Usage: upload.py <pr-url> <image>...

Prints a JSON object {image path: github.com/user-attachments URL} on stdout.
Progress goes to stderr. Nothing is ever posted: the draft is cleared at the end.

Drives the real keyboard and mouse through agent-desktop (macOS). Do not type
or click while it runs: the focused window is its input.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

TEXTAREA = "Markdown value"
ADD_FILES = "Paste, drop, or click to add files"
IMG = re.compile(r'<img [^>]*alt="([^"]*)"[^>]*src="(https://github\.com/user-attachments/assets/[^"]+)"')


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


def find(app, name=None, role=None, surface=None):
    args = ["find", "--app", app]
    if name:
        args += ["--name", name]
    if role:
        args += ["--role", role]
    if surface:
        args += ["--surface", surface]
    result = desktop(*args, check=False)
    return result["data"]["matches"] if result["ok"] else []


def wait_for(what, probe, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        found = probe()
        if found:
            return found
        time.sleep(0.1)
    fail(f"timed out waiting for {what}")


def sheet_nodes(app):
    """Flat list of nodes in the open file picker, or [] when none is open."""
    result = desktop("snapshot", "--app", app, "--surface", "sheet", "-i", "--compact", check=False)
    if not result["ok"]:
        return []
    nodes = []

    def walk(node):
        nodes.append(node)
        for child in node.get("children", []):
            walk(child)

    walk(result["data"]["tree"])
    return nodes


def default_browser():
    """Path of the app macOS opens https links with."""
    script = 'ObjC.import("AppKit"); $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("https://github.com")).path.js'
    out = subprocess.run(["osascript", "-l", "JavaScript", "-e", script], capture_output=True, text=True)
    if out.returncode != 0 or not out.stdout.strip():
        fail("could not find the default browser")
    return out.stdout.strip()


def textarea(app):
    matches = find(app, name=TEXTAREA)
    return matches[-1] if matches else None


def draft_images(app):
    """{alt text: url} of every image in the comment box; GitHub's alt is the file stem."""
    box = textarea(app)
    return {alt: url for alt, url in IMG.findall(box.get("value") or "")} if box else {}


def go_to_field(app):
    """The path field of the go-to-folder sheet: empty or absolute, unlike file rows."""
    fields = [n for n in sheet_nodes(app) if n["role"] == "textfield" and n.get("ref_id")]
    return next((n for n in reversed(fields) if not n.get("value") or n["value"].startswith("/")), None)


def selected_row(nodes, name):
    return next(
        (n for n in nodes if n["role"] == "textfield" and n.get("value") == name and "selected" in (n.get("states") or [])),
        None,
    )


def pick_files(app, folder, names):
    """Select every file of `folder` (which holds only `names`) in the open picker and confirm with Open."""
    desktop("press", "cmd+shift+g")
    goto = wait_for("the go-to-folder field", lambda: go_to_field(app))
    desktop("set-value", goto["ref_id"], folder)
    desktop("press", "return")
    desktop("press", "cmd+a")

    def all_selected():
        nodes = sheet_nodes(app)
        rows = {n.get("value") for n in nodes if n["role"] == "textfield" and "selected" in (n.get("states") or [])}
        return nodes if set(names) <= rows else None

    nodes = wait_for("all images to be selected", all_selected, timeout=5)
    opener = next(n for n in nodes if n["role"] == "button" and n.get("name") == "Open")
    desktop("click", opener["ref_id"])


def upload(app, folder, names):
    """Upload the files of `folder` in one go; returns {file name: url}."""
    add = wait_for("the add-files button", lambda: find(app, name=ADD_FILES))[-1]
    known = draft_images(app)
    desktop("click", add["ref_id"])
    wait_for("the file picker", lambda: sheet_nodes(app), timeout=10)
    pick_files(app, folder, names)
    stems = {os.path.splitext(n)[0]: n for n in names}

    def uploaded():
        fresh = {alt: url for alt, url in draft_images(app).items() if known.get(alt) != url}
        return fresh if set(stems) <= set(fresh) else None

    fresh = wait_for("the uploads to finish", uploaded, timeout=90)
    return {stems[stem]: fresh[stem] for stem in stems}


def clear_draft(app):
    """Real key events, so GitHub's persisted draft is cleared too."""
    box = textarea(app)
    if not box:
        return
    desktop("--headed", "focus", box["ref_id"])
    desktop("press", "cmd+a")
    desktop("press", "delete")
    wait_for("the comment box to empty", lambda: not (textarea(app) or {}).get("value"), timeout=5)


def main():
    if len(sys.argv) < 3:
        fail("usage: upload.py <pr-url> <image>...")
    pr_url, images = sys.argv[1], [os.path.abspath(p) for p in sys.argv[2:]]
    names = [os.path.basename(p) for p in images]
    if len(set(names)) != len(names):
        fail("image file names must be unique")
    for image in images:
        if not os.path.isfile(image):
            fail(f"not a file: {image}")

    # The picker selects a whole folder at once, so stage the images alone in one.
    with tempfile.TemporaryDirectory() as folder:
        for image in images:
            shutil.copy(image, folder)
        folder = os.path.realpath(folder)

        log("driving the keyboard and mouse: hands off until it finishes")
        browser = default_browser()
        app = os.path.basename(browser).removesuffix(".app")
        subprocess.run(["open", "-a", browser, pr_url], check=True)
        log(f"browser: {app}")
        wait_for("the PR comment box", lambda: textarea(app), timeout=45)

        try:
            by_name = upload(app, folder, names)
        finally:
            clear_draft(app)
    print(json.dumps({image: by_name[os.path.basename(image)] for image in images}, indent=2))


main()
