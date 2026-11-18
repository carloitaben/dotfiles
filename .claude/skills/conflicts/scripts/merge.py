#!/usr/bin/env python3
"""Deterministic steps of resolving a standalone branch's conflicts with its base.

  prepare   worktree + merge origin/<base>; lists conflicted files
  lockfile  regenerate a conflicted lockfile from the base's
  check     install dependencies, then typecheck and lint the changed packages
  finish    verify resolution, complete the merge, push, remove a temporary worktree

Every subcommand prints one JSON object. Exit code 1 means the step failed or needs attention.
"""

import argparse
import json
import os
import re
import subprocess
import sys

STATE_FILE = "conflicts.json"
CHECK_TIMEOUT_SECONDS = 900
TAIL_LINES = 40
LOCKFILE_COMMANDS = {
    "pnpm-lock.yaml": ["pnpm", "install", "--lockfile-only"],
    "package-lock.json": ["npm", "install", "--package-lock-only"],
}
KNOWN_LOCKFILES = LOCKFILE_COMMANDS.keys() | {"yarn.lock", "bun.lock", "bun.lockb", "Cargo.lock", "go.sum", "poetry.lock", "uv.lock"}
INSTALL_COMMANDS = {
    "pnpm-lock.yaml": ["pnpm", "install", "--frozen-lockfile"],
    "package-lock.json": ["npm", "ci"],
    "yarn.lock": ["yarn", "install", "--frozen-lockfile"],
    "bun.lock": ["bun", "install", "--frozen-lockfile"],
    "bun.lockb": ["bun", "install", "--frozen-lockfile"],
}
TYPECHECK_SCRIPTS = ("typecheck", "check:types", "check")
OPERATION_MARKERS = ("MERGE_HEAD", "rebase-merge", "rebase-apply", "CHERRY_PICK_HEAD", "REVERT_HEAD")


class Failure(Exception):
    pass


def git(*args, cwd=None, check=True):
    result = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
    if check and result.returncode:
        raise Failure(result.stderr.strip() or result.stdout.strip() or f"git {' '.join(args)} failed")
    return result


def out(*args, cwd=None):
    return git(*args, cwd=cwd).stdout.strip()


def git_dir(worktree):
    path = out("rev-parse", "--git-dir", cwd=worktree)
    return path if os.path.isabs(path) else os.path.join(worktree, path)


def repo_root(cwd=None):
    """Directory of the main checkout, wherever the script is run from."""
    common = out("rev-parse", "--git-common-dir", cwd=cwd)
    common = common if os.path.isabs(common) else os.path.join(cwd or os.getcwd(), common)
    return os.path.dirname(os.path.normpath(common))


def worktree_for(branch):
    for block in out("worktree", "list", "--porcelain").split("\n\n"):
        fields = dict(line.split(" ", 1) for line in block.splitlines() if " " in line)
        if fields.get("branch") == f"refs/heads/{branch}":
            return fields["worktree"]
    return None


def busy_reason(worktree):
    if out("status", "--porcelain", cwd=worktree):
        return f"{worktree} has uncommitted changes"
    for marker in OPERATION_MARKERS:
        if os.path.exists(os.path.join(git_dir(worktree), marker)):
            return f"{worktree} has an operation in progress ({marker})"
    return None


def read_state(worktree):
    with open(os.path.join(git_dir(worktree), STATE_FILE)) as handle:
        return json.load(handle)


def unmerged_files(worktree):
    return [line for line in out("diff", "--name-only", "--diff-filter=U", cwd=worktree).splitlines() if line]


def conflict_markers(worktree, paths):
    """Files that still hold conflict markers; text only."""
    hits = []
    for path in paths:
        try:
            with open(os.path.join(worktree, path), errors="ignore") as handle:
                if any(re.match(r"(<{7}|>{7})( |$)", line) for line in handle):
                    hits.append(path)
        except (FileNotFoundError, IsADirectoryError):
            continue
    return hits


def hunk_count(worktree, name):
    try:
        with open(os.path.join(worktree, name), errors="ignore") as handle:
            return sum(line.startswith("<<<<<<< ") for line in handle)
    except FileNotFoundError:
        return 0


def prepare(args):
    git("fetch", "origin")
    remote_sha = out("rev-parse", f"origin/{args.branch}")
    if remote_sha != args.sha:
        raise Failure(f"origin/{args.branch} is {remote_sha[:9]}, expected PR head {args.sha[:9]}; re-run the planner")

    local = git("rev-parse", "--verify", "--quiet", f"refs/heads/{args.branch}", check=False)
    local_sha = local.stdout.strip() if local.returncode == 0 else None
    if local_sha and local_sha != remote_sha:
        raise Failure(f"local {args.branch} is {local_sha[:9]} but PR head is {remote_sha[:9]}; resolve by hand, nothing was reset")

    path = worktree_for(args.branch)
    temporary = path is None
    if temporary:
        root = repo_root()
        slug = re.sub(r"[^A-Za-z0-9]+", "-", args.branch).strip("-")
        path = f"{root}-worktrees/conflicts-{slug}"
        if os.path.exists(path):
            raise Failure(f"{path} already exists")
        if local_sha:
            git("worktree", "add", path, args.branch)
        else:
            git("worktree", "add", "-b", args.branch, path, f"origin/{args.branch}")
    else:
        reason = busy_reason(path)
        if reason:
            raise Failure(reason)

    with open(os.path.join(git_dir(path), STATE_FILE), "w") as handle:
        json.dump({"branch": args.branch, "base": args.base, "temporary": temporary}, handle)

    merge = git("-c", "rerere.enabled=true", "merge", "--no-edit", f"origin/{args.base}", cwd=path, check=False)
    if merge.returncode == 0:
        merged = "Already up to date" not in merge.stdout
        return {"status": "clean", "worktree": path, "temporary": temporary, "branch": args.branch,
                "mergedLocally": merged, "files": []}

    conflicted = unmerged_files(path)
    if not conflicted:
        raise Failure(merge.stderr.strip() or merge.stdout.strip())
    codes = {line[3:]: line[:2] for line in out("status", "--porcelain", cwd=path).splitlines()}
    files = []
    for name in conflicted:
        files.append({"path": name, "state": codes.get(name, "UU"), "hunks": hunk_count(path, name),
                      "lockfile": os.path.basename(name) in KNOWN_LOCKFILES})
    return {"status": "conflicted", "worktree": path, "temporary": temporary, "branch": args.branch, "files": files}


def lockfile(args):
    state = read_state(args.worktree)
    base = f"origin/{state['base']}"
    present = [name for name in unmerged_files(args.worktree) if os.path.basename(name) in KNOWN_LOCKFILES]
    if not present:
        raise Failure("no conflicted lockfile")
    manifests = [name for name in unmerged_files(args.worktree) if os.path.basename(name) == "package.json"]
    if manifests:
        raise Failure(f"resolve {', '.join(manifests)} first; the lockfile is regenerated from it")

    results = []
    for name in present:
        command = LOCKFILE_COMMANDS.get(os.path.basename(name))
        if not command:
            results.append({"lockfile": name, "regenerated": False, "note": "no generator known; resolve by hand"})
            continue
        git("checkout", base, "--", name, cwd=args.worktree)
        run = subprocess.run(command, cwd=os.path.join(args.worktree, os.path.dirname(name)), text=True, capture_output=True)
        if run.returncode:
            raise Failure(f"{' '.join(command)} failed: {run.stderr.strip()[-500:]}")
        git("add", name, cwd=args.worktree)
        stat = out("diff", "--numstat", base, "--", name, cwd=args.worktree).split()
        results.append({"lockfile": name, "regenerated": True, "command": " ".join(command),
                        "addedLines": int(stat[0]) if stat else 0, "removedLines": int(stat[1]) if stat else 0})
    return {"status": "regenerated", "lockfiles": results}


def nearest_project(worktree, path):
    directory = os.path.dirname(os.path.join(worktree, path))
    while directory.startswith(worktree):
        for manifest in ("package.json", "Cargo.toml", "go.mod"):
            if os.path.exists(os.path.join(directory, manifest)):
                return directory, manifest
        if directory == worktree:
            break
        directory = os.path.dirname(directory)
    return None, None


def node_runner(worktree):
    for lock, command in INSTALL_COMMANDS.items():
        if os.path.exists(os.path.join(worktree, lock)):
            return lock, command
    return None, None


def run_step(label, command, cwd):
    try:
        result = subprocess.run(command, cwd=cwd, text=True, capture_output=True, timeout=CHECK_TIMEOUT_SECONDS)
    except FileNotFoundError:
        return {"step": label, "ok": False, "tail": f"{command[0]} not found"}
    except subprocess.TimeoutExpired:
        return {"step": label, "ok": False, "tail": f"timed out after {CHECK_TIMEOUT_SECONDS}s"}
    tail = "\n".join((result.stdout + result.stderr).strip().splitlines()[-TAIL_LINES:])
    return {"step": label, "ok": result.returncode == 0, "tail": tail}


def check(args):
    state = read_state(args.worktree)
    worktree = os.path.abspath(args.worktree)
    changed = [line for line in out("diff", "--name-only", f"origin/{state['base']}", cwd=worktree).splitlines() if line]
    projects = {}
    for path in changed:
        directory, manifest = nearest_project(worktree, path)
        if directory:
            projects[directory] = manifest

    steps = []
    lock, install = node_runner(worktree)
    needs_node = any(manifest == "package.json" for manifest in projects.values())
    if needs_node and install and not args.no_install and not os.path.isdir(os.path.join(worktree, "node_modules")):
        steps.append(run_step("install", install, worktree))
        if not steps[-1]["ok"]:
            return {"status": "failed", "checked": [], "steps": steps}

    runner = {"pnpm-lock.yaml": "pnpm", "package-lock.json": "npm", "yarn.lock": "yarn",
              "bun.lock": "bun", "bun.lockb": "bun"}.get(lock, "npm")
    for directory, manifest in sorted(projects.items()):
        label = os.path.relpath(directory, worktree)
        if manifest == "package.json":
            with open(os.path.join(directory, manifest)) as handle:
                scripts = json.load(handle).get("scripts", {})
            typecheck = next((name for name in TYPECHECK_SCRIPTS if name in scripts), None)
            for script in filter(None, [typecheck, "lint" if "lint" in scripts else None]):
                steps.append(run_step(f"{label}: {script}", [runner, "run", script], directory))
        elif manifest == "Cargo.toml":
            steps.append(run_step(f"{label}: cargo check", ["cargo", "check", "--all-targets"], directory))
        elif manifest == "go.mod":
            steps.append(run_step(f"{label}: go vet", ["go", "vet", "./..."], directory))

    status = "no-checks" if not steps else ("ok" if all(step["ok"] for step in steps) else "failed")
    return {"status": status, "checked": sorted(os.path.relpath(d, worktree) for d in projects), "steps": steps}


def finish(args):
    worktree = os.path.abspath(args.worktree)
    state = read_state(worktree)
    branch, base = state["branch"], state["base"]

    unmerged = unmerged_files(worktree)
    if unmerged:
        raise Failure(f"unmerged paths remain: {', '.join(unmerged)}")
    changed = [line for line in out("diff", "--name-only", f"origin/{base}", cwd=worktree).splitlines() if line]
    marked = conflict_markers(worktree, changed)
    if marked:
        raise Failure(f"conflict markers remain in: {', '.join(marked)}")
    untracked = [line[3:] for line in out("status", "--porcelain", cwd=worktree).splitlines() if line.startswith("??")]
    if untracked:
        raise Failure(f"untracked files: git add or remove {', '.join(untracked)}")

    if os.path.exists(os.path.join(git_dir(worktree), "MERGE_HEAD")):
        git("add", "-u", cwd=worktree)
        git("commit", "--no-edit", cwd=worktree)
    elif out("status", "--porcelain", cwd=worktree):
        git("add", "-u", cwd=worktree)
        git("commit", "-m", args.message or f"fix: adjust after merging {base}", cwd=worktree)

    before = git("rev-parse", "--verify", "--quiet", f"origin/{branch}", cwd=worktree, check=False).stdout.strip()
    push = git("push", "origin", f"HEAD:{branch}", cwd=worktree, check=False)
    if push.returncode:
        return {"status": "rejected", "branch": branch, "worktree": worktree, "error": push.stderr.strip()[-800:]}

    head = out("rev-parse", "HEAD", cwd=worktree)
    remote = out("ls-remote", "origin", f"refs/heads/{branch}", cwd=worktree).split()
    if not remote or remote[0] != head:
        raise Failure(f"push reported success but origin/{branch} is not {head[:9]}")

    removed = False
    if state["temporary"] and not out("status", "--porcelain", cwd=worktree):
        git("worktree", "remove", worktree, cwd=repo_root(worktree))
        removed = True
    return {"status": "pushed", "branch": branch, "from": before[:9] or None, "to": head[:9],
            "worktree": None if removed else worktree, "retained": not removed}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)

    sub = commands.add_parser("prepare")
    sub.add_argument("branch")
    sub.add_argument("--base", required=True)
    sub.add_argument("--sha", required=True, help="PR head SHA from the planner")
    sub.set_defaults(run=prepare)

    sub = commands.add_parser("lockfile")
    sub.add_argument("worktree")
    sub.set_defaults(run=lockfile)

    sub = commands.add_parser("check")
    sub.add_argument("worktree")
    sub.add_argument("--no-install", action="store_true")
    sub.set_defaults(run=check)

    sub = commands.add_parser("finish")
    sub.add_argument("worktree")
    sub.add_argument("--message", help="commit message when the merge was already complete")
    sub.set_defaults(run=finish)

    args = parser.parse_args()
    try:
        result = args.run(args)
    except Failure as error:
        print(json.dumps({"status": "failed", "error": str(error)}, indent=2))
        sys.exit(1)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["status"] not in ("failed", "rejected") else 1)


if __name__ == "__main__":
    main()
