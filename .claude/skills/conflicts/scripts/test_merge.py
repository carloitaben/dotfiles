import json
import os
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
MERGE = os.path.join(HERE, "merge.py")
REPORT = os.path.join(HERE, "report.py")


def git(*args, cwd):
    return subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True, check=True).stdout.strip()


def script(*args, cwd, stdin=None):
    result = subprocess.run(["python3", *args], cwd=cwd, text=True, capture_output=True, input=stdin)
    return result.returncode, json.loads(result.stdout) if result.stdout.strip().startswith("{") else result.stdout


class MergeFlow(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = os.path.realpath(self.tmp.name)
        self.origin = os.path.join(root, "origin.git")
        self.repo = os.path.join(root, "repo")
        git("init", "--bare", "-b", "main", self.origin, cwd=root)
        git("clone", self.origin, self.repo, cwd=root)
        for key, value in (("user.name", "t"), ("user.email", "t@t"), ("commit.gpgsign", "false")):
            git("config", key, value, cwd=self.repo)
        self.write("app.txt", "one\n")
        git("add", ".", cwd=self.repo)
        git("commit", "-m", "init", cwd=self.repo)
        git("push", "origin", "main", cwd=self.repo)
        git("checkout", "-b", "feature", cwd=self.repo)
        self.write("app.txt", "feature\n")
        git("commit", "-am", "feature", cwd=self.repo)
        git("push", "origin", "feature", cwd=self.repo)
        self.head = git("rev-parse", "HEAD", cwd=self.repo)
        git("checkout", "main", cwd=self.repo)
        git("branch", "-D", "feature", cwd=self.repo)
        self.write("app.txt", "main\n")
        git("commit", "-am", "main change", cwd=self.repo)
        git("push", "origin", "main", cwd=self.repo)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, text):
        with open(os.path.join(self.repo, name), "w") as handle:
            handle.write(text)

    def prepare(self, sha=None):
        return script(MERGE, "prepare", "feature", "--base", "main", "--sha", sha or self.head, cwd=self.repo)

    def test_conflict_resolve_finish_pushes_and_removes_temporary_worktree(self):
        code, prepared = self.prepare()
        self.assertEqual(code, 0)
        self.assertEqual(prepared["status"], "conflicted")
        self.assertEqual([(f["path"], f["hunks"]) for f in prepared["files"]], [("app.txt", 1)])
        worktree = prepared["worktree"]
        self.assertTrue(prepared["temporary"])

        code, refused = script(MERGE, "finish", worktree, cwd=self.repo)
        self.assertEqual(code, 1)
        self.assertIn("unmerged", refused["error"])

        with open(os.path.join(worktree, "app.txt"), "w") as handle:
            handle.write("both\n")
        git("add", "app.txt", cwd=worktree)
        code, finished = script(MERGE, "finish", worktree, cwd=self.repo)
        self.assertEqual((code, finished["status"], finished["retained"]), (0, "pushed", False))
        self.assertFalse(os.path.exists(worktree))
        self.assertEqual(git("rev-parse", "refs/heads/feature", cwd=self.origin), git("rev-parse", "feature", cwd=self.repo))

    def test_markers_left_behind_block_finish(self):
        _, prepared = self.prepare()
        worktree = prepared["worktree"]
        git("add", "app.txt", cwd=worktree)
        code, refused = script(MERGE, "finish", worktree, cwd=self.repo)
        self.assertEqual(code, 1)
        self.assertIn("conflict markers", refused["error"])

    def test_stale_planner_sha_fails_without_creating_a_worktree(self):
        code, failed = self.prepare(sha="0" * 40)
        self.assertEqual(code, 1)
        self.assertIn("re-run the planner", failed["error"])
        self.assertNotIn("conflicts-feature", git("worktree", "list", cwd=self.repo))

    def test_clean_merge_is_reported_without_pushing(self):
        git("checkout", "-b", "other", "main~1", cwd=self.repo)
        self.write("extra.txt", "x\n")
        git("add", ".", cwd=self.repo)
        git("commit", "-m", "extra", cwd=self.repo)
        git("push", "origin", "other", cwd=self.repo)
        sha = git("rev-parse", "HEAD", cwd=self.repo)
        git("checkout", "main", cwd=self.repo)
        git("branch", "-D", "other", cwd=self.repo)
        code, prepared = script(MERGE, "prepare", "other", "--base", "main", "--sha", sha, cwd=self.repo)
        self.assertEqual((code, prepared["status"], prepared["mergedLocally"]), (0, "clean", True))


class ReportTable(unittest.TestCase):
    def test_renders_one_row_per_target(self):
        items = [{"pr": 1, "url": "https://x/1", "branch": "a", "status": "pushed", "resolved": ["f: took base"],
                  "push": "aaa..bbb", "worktrees": []}]
        code, table = script(REPORT, cwd=HERE, stdin=json.dumps(items))
        self.assertEqual(code, 0)
        self.assertIn("| [#1](https://x/1) | pushed | 1 | aaa..bbb | - |", table)


if __name__ == "__main__":
    unittest.main()
