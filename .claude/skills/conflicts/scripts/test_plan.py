import unittest

from plan import plan


def pr(number, branch, base="main", repo="owner/repo"):
    return {"number": number, "head": {"ref": branch, "sha": str(number),
            "repo": {"full_name": repo}}, "base": {"ref": base},
            "html_url": f"https://github.com/owner/repo/pull/{number}"}


class PlanTests(unittest.TestCase):
    def test_stack_is_complete_ordered_and_deduplicated(self):
        prs = [pr(3, "c", "b"), pr(1, "a"), pr(2, "b", "a")]
        result = plan("owner/repo", "main", prs, ["3", "a"])
        self.assertEqual(len(result["units"]), 1)
        self.assertEqual([b["prNumber"] for b in result["units"][0]["branches"]], [1, 2, 3])
        self.assertEqual([b["requested"] for b in result["units"][0]["branches"]], [True, False, True])

    def test_current_branch_and_nondefault_base(self):
        result = plan("owner/repo", "main", [pr(1, "a", "release")], [], "a")
        self.assertEqual(result["units"][0]["kind"], "stack")

    def test_foreign_url_and_missing_pr_rejected(self):
        for target in ["https://github.com/other/repo/pull/1", "missing"]:
            with self.assertRaises(ValueError):
                plan("owner/repo", "main", [pr(1, "a")], [target])

    def test_fork_and_branching_rejected(self):
        with self.assertRaises(ValueError):
            plan("owner/repo", "main", [pr(1, "a", repo="fork/repo")], ["1"])
        with self.assertRaises(ValueError):
            plan("owner/repo", "main", [pr(1, "a"), pr(2, "b", "a"), pr(3, "c", "a")], ["1"])


if __name__ == "__main__":
    unittest.main()
