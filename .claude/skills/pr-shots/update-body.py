#!/usr/bin/env python3
"""Read this session's shots manifest; fill a PR description's `## Proof` section.

An entry is a single `shot` (one image) or a before/after `comparison` (two images).

Usage:
  update-body.py check               exit 1 unless every shot is present and current
  update-body.py paths               print the image paths to upload, one per line
  update-body.py write <pr> <urls>   <urls> is upload.py's JSON {image path: url} (a file)

`check` is stale when a shot's head_sha differs from HEAD.
"""
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def fail(msg):
    sys.exit(f"[pr-shots] {msg}")


def manifest():
    session = os.environ.get("CLAUDE_CODE_SESSION_ID") or fail("CLAUDE_CODE_SESSION_ID is not set")
    path = Path.home() / ".claude" / "shots" / session / "manifest.json"
    if not path.exists():
        fail(f"no shots for this session: {path}")
    return json.loads(path.read_text())


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


def images(e):
    return [e["image"]] if e["kind"] == "shot" else [e["before"], e["after"]]


def check(entries):
    head = run("git", "rev-parse", "HEAD").strip()
    problems = []
    for e in entries:
        for image in images(e):
            if not Path(image).is_file():
                problems.append(f"{e['name']}: missing image {image}")
        if e.get("head_sha") != head:
            problems.append(f"{e['name']}: stale, shot at {str(e.get('head_sha'))[:8]}, HEAD is {head[:8]}")
    if problems:
        fail("\n".join(problems))


def section(entries, urls):
    out = ["## Proof", ""]
    for e in entries:
        out += [f"**{e['name']}**" + (f": {e['note']}" if e["note"] else ""), ""]
        if e["kind"] == "shot":
            out += [f"![{e['name']}]({urls[e['image']]})", ""]
        else:
            out += ["|Before|After|", "|:-:|:-:|",
                    f"|![Before]({urls[e['before']]})|![After]({urls[e['after']]})|", ""]
    return "\n".join(out)


def write(pr, urls_file):
    entries, urls = manifest(), json.loads(Path(urls_file).read_text())
    body = run("gh", "pr", "view", pr, "--json", "body", "-q", ".body").rstrip("\n")
    new = section(entries, urls).rstrip("\n")
    pattern = re.compile(r"^## Proof\n.*?(?=^## |\Z)", re.S | re.M)
    body = pattern.sub(new + "\n\n", body, count=1) if pattern.search(body) else f"{body}\n\n{new}"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
        f.write(body.rstrip("\n") + "\n")
    run("gh", "pr", "edit", pr, "--body-file", f.name)
    final = run("gh", "pr", "view", pr, "--json", "body", "-q", ".body")
    count = final.count("user-attachments/assets/")
    expected = sum(len(images(e)) for e in entries)
    print(f"{count} images in the PR body, expected {expected}")
    sys.exit(0 if count == expected else 1)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "check":
        check(manifest())
    elif cmd == "paths":
        print("\n".join(image for e in manifest() for image in images(e)))
    elif cmd == "write" and len(sys.argv) == 4:
        write(sys.argv[2], sys.argv[3])
    else:
        fail(__doc__)


main()
