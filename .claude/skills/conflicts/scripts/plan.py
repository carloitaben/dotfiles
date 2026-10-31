#!/usr/bin/env python3
"""Resolve conflict targets and group their open PRs; never mutate git state."""

import json
import re
import subprocess
import sys
from urllib.parse import urlparse


def run(*args):
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode:
        raise ValueError(result.stderr.strip() or f"{' '.join(args)} failed")
    return result.stdout.strip()


def plan(repo, default, prs, args, current=None):
    by_number = {pr["number"]: pr for pr in prs}
    by_head = {}
    for pr in prs:
        key = (pr["head"]["repo"]["full_name"].lower(), pr["head"]["ref"])
        by_head.setdefault(key, []).append(pr)

    selected = []
    for arg in args or [current]:
        if not arg:
            raise ValueError("No current branch (detached HEAD); specify a target")
        url = urlparse(arg if "://" in arg else "https://" + arg)
        match = re.fullmatch(r"/([^/]+)/([^/]+)/pull/(\d+)/?", url.path)
        if url.hostname and url.hostname.lower() == "github.com" and match:
            if f"{match[1]}/{match[2]}".lower() != repo.lower():
                raise ValueError(f"PR URL is not in origin repository: {arg}")
            arg = match[3]
        if arg.isdigit():
            matches = [by_number[int(arg)]] if int(arg) in by_number else []
        else:
            matches = by_head.get((repo.lower(), arg), [])
        if len(matches) != 1:
            raise ValueError(f"Expected one open PR for {arg!r}, found {len(matches)}")
        if matches[0] not in selected:
            selected.append(matches[0])

    # A PR's base belongs to the repository hosting that PR, not its head fork.
    children = {pr["number"]: [] for pr in prs}
    parent = {}
    for pr in prs:
        candidates = by_head.get((repo.lower(), pr["base"]["ref"]), [])
        if len(candidates) > 1:
            raise ValueError(f"Ambiguous base branch {pr['base']['ref']!r}")
        if candidates:
            parent[pr["number"]] = candidates[0]["number"]
            children[candidates[0]["number"]].append(pr["number"])

    units = []
    seen = set()
    for pr in selected:
        root = pr["number"]
        ancestors = set()
        while root in parent:
            if root in ancestors:
                raise ValueError("Cycle in PR base relationships")
            ancestors.add(root)
            root = parent[root]
        if root in seen:
            continue
        seen.add(root)
        chain = []
        node = root
        while True:
            item = by_number[node]
            if item["head"]["repo"]["full_name"].lower() != repo.lower():
                raise ValueError(f"Fork PR #{node} requires manual handling")
            chain.append({"branch": item["head"]["ref"], "headSha": item["head"]["sha"],
                          "base": item["base"]["ref"], "prNumber": node,
                          "url": item["html_url"], "requested": item in selected})
            if len(children[node]) > 1:
                raise ValueError(f"Branching stack at PR #{node}; gh-stack requires a linear stack")
            if not children[node]:
                break
            node = children[node][0]
        units.append({"kind": "stack" if len(chain) > 1 or chain[0]["base"] != default else "standalone",
                      "branches": chain})
    return {"repository": repo, "defaultBranch": default, "units": units}


def main():
    remote = run("git", "remote", "get-url", "origin")
    match = re.fullmatch(r"(?:https://github\.com/|ssh://git@github\.com/|git@github\.com:)([^/]+/[^/]+?)(?:\.git)?/?", remote, re.IGNORECASE)
    if not match:
        raise ValueError(f"Unsupported origin URL (expected github.com): {remote}")
    repo_data = json.loads(run("gh", "repo", "view", match[1], "--json", "nameWithOwner,defaultBranchRef"))
    repo = repo_data["nameWithOwner"]
    pages = run("gh", "api", "--paginate", "--slurp", f"repos/{repo}/pulls?state=open&per_page=100")
    prs = [pr for page in json.loads(pages) for pr in page]
    current = None if len(sys.argv) > 1 else run("git", "branch", "--show-current")
    print(json.dumps(plan(repo, repo_data["defaultBranchRef"]["name"], prs, sys.argv[1:], current), indent=2))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"conflicts plan: {error}", file=sys.stderr)
        sys.exit(1)
