#!/usr/bin/env python3
"""Render the final conflicts table from agent results.

Reads a JSON array on stdin. Each item:
  {"pr": 12, "url": "...", "branch": "feature/x", "status": "clean|pushed|failed|needs-input",
   "resolved": ["path: how it was resolved", ...], "push": "abc1234..def5678" | null,
   "worktrees": ["/path", ...], "note": "optional"}
"""

import json
import sys


def label(item):
    name = f"#{item['pr']}" if item.get("pr") else item["branch"]
    return f"[{name}]({item['url']})" if item.get("url") else name


def row(item):
    worktrees = ", ".join(f"`{path}`" for path in item.get("worktrees", [])) or "-"
    note = f" ({item['note']})" if item.get("note") else ""
    return "| {} | {}{} | {} | {} | {} |".format(
        label(item), item["status"], note, len(item.get("resolved", [])), item.get("push") or "-", worktrees)


def render(items):
    header = ["| Target | Status | Auto-resolved | Push | Retained worktree |", "|---|---|---|---|---|"]
    return "\n".join(header + [row(item) for item in items])


if __name__ == "__main__":
    print(render(json.load(sys.stdin)))
