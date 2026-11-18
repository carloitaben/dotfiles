import unittest

from plan import plan


def pr(number, branch, base="main", repo="owner/repo", author="me"):
    return {"number": number, "user": {"login": author}, "head": {"ref": branch, "sha": str(number),
            "repo": {"full_name": repo}}, "base": {"ref": base},
            "html_url": f"https://github.com/owner/repo/pull/{number}"}


class PlanTests(unittest.TestCase):
    def test_stack_is_complete_ordered_and_deduplicated(self):
        prs = [pr(3, "c", "b"), pr(1, "a"), pr(2, "b", "a")]
        result = plan("owner/repo", "main", prs, ["3", "a"], me="me")
        self.assertEqual(len(result["units"]), 1)
        self.assertEqual([b["prNumber"] for b in result["units"][0]["branches"]], [1, 2, 3])
        self.assertEqual([b["requested"] for b in result["units"][0]["branches"]], [True, False, True])

    def test_single_pr_is_standalone_whatever_its_base(self):
        result = plan("owner/repo", "main", [pr(1, "a", "release")], [], "a", me="me")
        self.assertEqual(result["units"][0]["kind"], "standalone")

    def test_chained_prs_are_a_stack(self):
        result = plan("owner/repo", "main", [pr(1, "a"), pr(2, "b", "a")], ["2"], me="me")
        self.assertEqual(result["units"][0]["kind"], "stack")

    def test_foreign_url_and_missing_pr_rejected(self):
        for target in ["https://github.com/other/repo/pull/1", "missing"]:
            with self.assertRaises(ValueError):
                plan("owner/repo", "main", [pr(1, "a")], [target], me="me")

    def test_fork_and_branching_rejected(self):
        with self.assertRaises(ValueError):
            plan("owner/repo", "main", [pr(1, "a", repo="fork/repo")], ["1"], me="me")
        with self.assertRaises(ValueError):
            plan("owner/repo", "main", [pr(1, "a"), pr(2, "b", "a"), pr(3, "c", "a")], ["1"], me="me")

    def test_others_pr_bails_unless_consented(self):
        theirs = [pr(1, "a", author="someone")]
        with self.assertRaises(ValueError):
            plan("owner/repo", "main", theirs, ["1"], me="me")
        self.assertEqual(len(plan("owner/repo", "main", theirs, ["1"], me="Me", allow_others=True)["units"]), 1)

    def test_any_foreign_pr_in_a_stack_bails(self):
        prs = [pr(1, "a"), pr(2, "b", "a", author="someone")]
        with self.assertRaises(ValueError):
            plan("owner/repo", "main", prs, ["1"], me="me")

    def test_current_branch_without_pr_bails(self):
        with self.assertRaisesRegex(ValueError, "No open PR for the current branch"):
            plan("owner/repo", "main", [pr(1, "a")], [], "wip", me="me")


if __name__ == "__main__":
    unittest.main()
