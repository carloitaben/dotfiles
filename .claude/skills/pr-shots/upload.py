#!/usr/bin/env python3
"""Upload images to GitHub through a PR's comment box, then clear the box.

Usage: upload.py <pr-url> <image>...   (png or jpg)

Prints a JSON object {image path: github.com/user-attachments URL} on stdout.
Progress goes to stderr. Nothing is ever posted: the draft is cleared at the end.

Runs in agent-browser's own headless browser, session `gh`, so it never touches your
keyboard, mouse, clipboard or windows. Each image is pasted into the comment box as a
synthetic paste event, which GitHub uploads like a real paste.

Needs a signed-in `gh` session: a persistent profile at ~/.agent-browser/profiles/gh.
One-time setup (sign in, then close the window):
  agent-browser --session gh --profile ~/.agent-browser/profiles/gh --headed open https://github.com/login
"""
import base64
import json
import os
import re
import subprocess
import sys
import time

SESSION = "gh"
PROFILE = os.path.expanduser("~/.agent-browser/profiles/gh")
SETUP = f"agent-browser --session {SESSION} --profile {PROFILE} --headed open https://github.com/login"
TEXTAREA = 'textarea[aria-label="Markdown value"]'
IMG_URL = re.compile(r'<img [^>]*src="(https://github\.com/user-attachments/assets/[^"]+)"')
MIME = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg"}
MAX_BYTES = 10_000_000  # GitHub rejects larger images


def log(msg):
    print(f"[pr-shots] {msg}", file=sys.stderr)


def fail(msg):
    sys.exit(f"[pr-shots] {msg}")


def browser(*args, stdin=None):
    """Runs one agent-browser command. `open` is retried twice: the first navigation
    can time out, and the previous run's daemon may still be shutting down. `stdin` feeds the command's standard input."""
    for attempt in range(3):
        r = subprocess.run(["agent-browser", "--session", SESSION, "--profile", PROFILE, *args], input=stdin, capture_output=True, text=True)
        transient = any(m in r.stdout + r.stderr for m in ("Navigation failed", "Could not configure browser"))
        if not (r.returncode and args[0] == "open" and transient):
            break
        log(f"{args[0]} failed, retry {attempt + 1}")
        time.sleep(2)
    if r.returncode:
        fail(f"agent-browser {' '.join(args)[:60]}: {(r.stderr or r.stdout).strip()}")
    return r.stdout.strip()


def evaluate(js):
    """Runs `js` in the page. The script travels over stdin: a pasted image is megabytes of base64, too big for argv."""
    return json.loads(browser("eval", "--stdin", stdin=js))


def require_session():
    """Fail fast and loud when the `gh` session is not signed in to GitHub."""
    browser("open", "https://github.com/")
    user = evaluate('document.querySelector("meta[name=user-login]")?.content || ""')
    if not user:
        fail(
            f"the `{SESSION}` agent-browser session is not signed in to GitHub.\n"
            f"Sign in once, then close the window:\n"
            f"  {SETUP}"
        )
    log(f"signed in as {user}")


def draft_urls():
    value = evaluate(f"document.querySelector({json.dumps(TEXTAREA)})?.value || ''")
    return IMG_URL.findall(value)


def wait_for(what, probe, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        found = probe()
        if found:
            return found
        time.sleep(0.25)
    fail(f"timed out waiting for {what}")


def paste_image(image):
    """Paste one image into the comment box; returns its new upload URL."""
    ext = os.path.splitext(image)[1].lower()
    data = base64.b64encode(open(image, "rb").read()).decode()
    known = set(draft_urls())
    evaluate(f"""(() => {{
      const ta = document.querySelector({json.dumps(TEXTAREA)});
      const bytes = Uint8Array.from(atob("{data}"), c => c.charCodeAt(0));
      const file = new File([bytes], {json.dumps(os.path.basename(image))}, {{type: "{MIME[ext]}"}});
      const clipboardData = new DataTransfer();
      clipboardData.items.add(file);
      ta.focus();
      ta.dispatchEvent(new ClipboardEvent("paste", {{clipboardData, bubbles: true, cancelable: true}}));
      return true;
    }})()""")

    def uploaded():
        fresh = [url for url in draft_urls() if url not in known]
        return fresh[0] if fresh else None

    return wait_for(f"{os.path.basename(image)} to upload", uploaded, timeout=90)


def clear_draft():
    """Empty the box through React's own value setter, so GitHub's persisted draft is
    cleared too. Fails loudly if the box is still not empty."""
    evaluate(f"""(() => {{
      const ta = document.querySelector({json.dumps(TEXTAREA)});
      Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, "value").set.call(ta, "");
      ta.dispatchEvent(new Event("input", {{bubbles: true}}));
      return true;
    }})()""")
    time.sleep(1)
    if evaluate(f"document.querySelector({json.dumps(TEXTAREA)}).value.length"):
        fail("could not clear the PR comment box; clear it by hand")


def main():
    if len(sys.argv) < 3:
        fail("usage: upload.py <pr-url> <image>...")
    pr_url, images = sys.argv[1], [os.path.abspath(p) for p in sys.argv[2:]]
    for image in images:
        if not os.path.isfile(image):
            fail(f"not a file: {image}")
        if os.path.splitext(image)[1].lower() not in MIME:
            fail(f"only png and jpg are supported: {image}")
        if os.path.getsize(image) > MAX_BYTES:
            fail(f"image over GitHub's {MAX_BYTES // 1_000_000} MB limit, shrink it first: {image}")

    require_session()
    browser("open", pr_url)
    wait_for("the PR comment box", lambda: evaluate(f"!!document.querySelector({json.dumps(TEXTAREA)})"), timeout=45)

    clear_draft()  # start from an empty box: a leftover draft would hide new URLs
    try:
        urls = {image: paste_image(image) for image in images}
    finally:
        clear_draft()
        browser("close")
    print(json.dumps(urls, indent=2))


main()
