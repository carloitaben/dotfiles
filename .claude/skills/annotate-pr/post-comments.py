#!/usr/bin/env python3
"""Verify and post inline PR review comments.

Usage: post-comments.py <dry|post> <comments.json>

comments.json is a list of:
  {"pr": 1272, "path": "src/a.ts", "line": 88, "snippet": "text on that line", "body": "Note: ..."}

dry:  checks that each PR's head commit has `snippet` on `path:line`.
post: same check, then posts the comment on the head commit (RIGHT side).
Run from inside the repo.
"""
import json
import subprocess
import sys


def run(args, stdin=None):
    return subprocess.run(args, input=stdin, capture_output=True, text=True)


def head_of(pr):
    out = run(["gh", "pr", "view", str(pr), "--json", "headRefOid,headRefName"])
    if out.returncode != 0:
        sys.exit(out.stderr)
    info = json.loads(out.stdout)
    return info["headRefOid"], info["headRefName"]


def file_at(oid, branch, path):
    out = run(["git", "show", f"{oid}:{path}"])
    if out.returncode != 0:
        run(["git", "fetch", "-q", "origin", branch])
        out = run(["git", "show", f"{oid}:{path}"])
    return out.stdout.split("\n") if out.returncode == 0 else None


def main():
    mode, source = sys.argv[1], sys.argv[2]
    if mode not in ("dry", "post"):
        sys.exit(__doc__)
    comments = json.load(open(source))
    repo = json.loads(run(["gh", "repo", "view", "--json", "nameWithOwner"]).stdout)["nameWithOwner"]
    heads = {}
    bad = 0
    for c in comments:
        pr, path, line = c["pr"], c["path"], c["line"]
        if pr not in heads:
            heads[pr] = head_of(pr)
        oid, branch = heads[pr]
        lines = file_at(oid, branch, path)
        found = lines[line - 1] if lines and line <= len(lines) else None
        ok = found is not None and c["snippet"] in found
        print(f"{'OK ' if ok else 'BAD'} #{pr} {path}:{line}  {(found or '<missing>').strip()[:60]}")
        if not ok:
            bad += 1
            continue
        if mode == "post":
            payload = json.dumps(
                {"body": c["body"], "commit_id": oid, "path": path, "line": line, "side": "RIGHT"}
            )
            res = run(
                ["gh", "api", f"repos/{repo}/pulls/{pr}/comments", "--input", "-", "-q", ".html_url"],
                stdin=payload,
            )
            print("   ->", res.stdout.strip() or res.stderr.strip())
    print("bad:", bad)
    sys.exit(1 if bad else 0)


main()
