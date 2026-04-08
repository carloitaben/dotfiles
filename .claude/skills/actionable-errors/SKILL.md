---
name: actionable-errors
description: Write actionable error messages that help users fix issues and complete their goals. Use when asked to "improve error messages", "write better errors", "actionable errors", or "user-friendly errors".
license: MIT
metadata:
  author: carloitaben
  version: "1.0"
---

Actionable error messages tell users what went wrong, how to fix it, and how to get help.

# Three Components of Actionable Errors

## 1. What went wrong
Explain why the request can't be completed. This builds trust and helps users understand the issue.

## 2. How to proceed toward their goal
Always tell users how to move past the error and complete their objective. Don't just state the problem.

## 3. How to get help
Provide a path to more assistance (e.g., `/help` command or documentation link) if users remain stuck.

---

# Actionable vs Inactionable Example

## Scenario
User enters a date in wrong format (e.g., "November 19, 2021") but the app expects "2021-11-19".

## Actionable Error

> I don't recognize the date format you entered. Write dates as `yyyy-mm-dd`; for example, `2000-01-31`. For help, type `/help`.

**Why it works:**
- Says what went wrong (unrecognized format)
- Shows expected format with example
- Offers help command

## Inactionable Error

> Enter the correct date format.

**Why it fails:**
- Doesn't explain what went wrong
- Doesn't show expected format
- Offers no help path

---

# Key Principles

- Never show generic errors like "An error occurred"
- Always explain the "why" behind the error
- Provide concrete examples when showing expected formats
- Include a help path in every error message
- Think from the user's perspective: can they act on this?
