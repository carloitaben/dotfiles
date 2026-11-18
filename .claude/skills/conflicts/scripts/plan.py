#!/usr/bin/env python3
"""Resolve conflict targets and group their open PRs; never mutate git state."""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from urllib.parse import urlparse

OPERATION_MARKERS = {
    "MERGE_HEAD": "merge",
    "rebase-merge": "rebase",
    "rebase-apply": "rebase",
    "CHERRY_PICK_HEAD": "cherry-pick",
    "REVERT_HEAD": "revert",
}
MERGEABILITY_POLLS = 5


def run(*args):
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode:
        raise ValueError(result.stderr.strip() or f"{' '.join(args)} failed")
    return result.stdout.strip()


def plan(repo, default, prs, args, current=None, *, me, allow_others=False):
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
        if not matches and arg == current:
            raise ValueError(f"No open PR for the current branch {arg!r}; pass a PR or branch")
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
            author = item["user"]["login"]
            if author.lower() != me.lower() and not allow_others:
                raise ValueError(f"PR #{node} is by {author}, not {me}; pass --allow-others only with the owner's explicit consent")
            if len(children[node]) > 1:
                raise ValueError(f"Branching stack at PR #{node}; gh-stack requires a linear stack")
            if not children[node]:
                break
            node = children[node][0]
        units.append({"kind": "stack" if len(chain) > 1 else "standalone", "branches": chain})
    return {"repository": repo, "defaultBranch": default, "units": units}


def worktrees():
    """Map branch name to {path, sha} for every checked-out worktree."""
    found = {}
    for block in run("git", "worktree", "list", "--porcelain").split("\n\n"):
        fields = dict(line.split(" ", 1) for line in block.splitlines() if " " in line)
        if "worktree" in fields and fields.get("branch", "").startswith("refs/heads/"):
            found[fields["branch"][len("refs/heads/"):]] = {"path": fields["worktree"], "sha": fields.get("HEAD")}
    return found


def operation_in_progress(path):
    git_dir = run("git", "-C", path, "rev-parse", "--git-dir")
    git_dir = git_dir if os.path.isabs(git_dir) else os.path.join(path, git_dir)
    for marker, name in OPERATION_MARKERS.items():
        if os.path.exists(os.path.join(git_dir, marker)):
            return name
    return None


def local_state(branch, pr_sha, trees):
    """Local facts that decide whether an agent may touch this branch; blockers need the user."""
    try:
        local_sha = run("git", "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}")
    except ValueError:
        local_sha = None
    state = {"localSha": local_sha, "worktree": None, "blockers": []}
    if local_sha and local_sha != pr_sha:
        state["blockers"].append(f"local branch at {local_sha[:9]} differs from PR head {pr_sha[:9]}")
    if branch in trees:
        path = trees[branch]["path"]
        state["worktree"] = path
        if run("git", "-C", path, "status", "--porcelain"):
            state["blockers"].append(f"worktree {path} has uncommitted changes")
        operation = operation_in_progress(path)
        if operation:
            state["blockers"].append(f"worktree {path} has a {operation} in progress")
    return state


def conflicting_targets(repo, gh_flags):
    """PR numbers whose mergeability is CONFLICTING, polling while GitHub still computes it."""
    command = ["gh", "pr", "list", "--repo", repo, "--state", "open", "--limit", "200",
               "--json", "number,mergeable", *gh_flags]
    for attempt in range(MERGEABILITY_POLLS):
        listed = json.loads(run(*command))
        unknown = [pr["number"] for pr in listed if pr["mergeable"] == "UNKNOWN"]
        if not unknown:
            break
        if attempt < MERGEABILITY_POLLS - 1:
            time.sleep(3)
    return [str(pr["number"]) for pr in listed if pr["mergeable"] == "CONFLICTING"], unknown


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="*", help="PR number, PR URL or branch; default is the current branch's PR")
    parser.add_argument("--conflicting", action="store_true", help="plan every open PR that conflicts with its base")
    parser.add_argument("--author", help="with --conflicting: only PRs by this login (default @me)")
    parser.add_argument("--allow-others", action="store_true",
                        help="plan PRs authored by someone else; only with the owner's explicit consent")
    parser.add_argument("--draft", action="store_true", help="with --conflicting: only draft PRs")
    args = parser.parse_args()
    if args.targets and args.conflicting:
        raise ValueError("Pass explicit targets or --conflicting, not both")
    if (args.author or args.draft) and not args.conflicting:
        raise ValueError("--author and --draft need --conflicting")

    remote = run("git", "remote", "get-url", "origin")
    match = re.fullmatch(r"(?:https://github\.com/|ssh://git@github\.com/|git@github\.com:)([^/]+/[^/]+?)(?:\.git)?/?", remote, re.IGNORECASE)
    if not match:
        raise ValueError(f"Unsupported origin URL (expected github.com): {remote}")
    repo_data = json.loads(run("gh", "repo", "view", match[1], "--json", "nameWithOwner,defaultBranchRef"))
    repo = repo_data["nameWithOwner"]
    pages = run("gh", "api", "--paginate", "--slurp", f"repos/{repo}/pulls?state=open&per_page=100")
    prs = [pr for page in json.loads(pages) for pr in page]
    targets, unknown = args.targets, []
    if args.conflicting:
        author = args.author or (None if args.allow_others else "@me")
        gh_flags = (["--author", author] if author else []) + (["--draft"] if args.draft else [])
        targets, unknown = conflicting_targets(repo, gh_flags)
    current = None if targets or args.conflicting else run("git", "branch", "--show-current")
    default = repo_data["defaultBranchRef"]["name"]
    me = run("gh", "api", "user", "--jq", ".login")
    result = plan(repo, default, prs, targets, current, me=me, allow_others=args.allow_others) \
        if targets or not args.conflicting else {"repository": repo, "defaultBranch": default, "units": []}
    trees = worktrees()
    for unit in result["units"]:
        for branch in unit["branches"]:
            branch["local"] = local_state(branch["branch"], branch["headSha"], trees)
    result["mergeabilityUnknown"] = unknown
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"conflicts plan: {error}", file=sys.stderr)
        sys.exit(1)
