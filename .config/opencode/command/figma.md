---
description: Use the Figma MCP to implement a Figma design as a React component
agent: build
subtask: true
---

You are implementing a Figma design as a React component.

Design to implement:
$ARGUMENTS

If no Figma link is provided, stop and ask the user to provide one.

Example:

- `https://www.figma.com/file/...?...&node-id=1-2`

Use the Figma MCP server to get design tokens and layout information.

IMPORTANT: Convert node IDs from dash-separated to colon-separated before using the Figma MCP.

Before:
?node-id=1-2

After:
?node-id=1:2

---

# REQUIRED PROCESS

## 1) Parse Figma Reference

- Extract the Figma file ID
- Extract the node ID
- Convert the node ID to colon-separated format
- Confirm the target frame/component is the correct one

---

## 2) Inspect Design Data

- Fetch layout structure
- Fetch component details
- Fetch design tokens when available
- Identify spacing, typography, colors, sizing, and variants

---

## 3) Inspect Local UI Constraints

- Read the Tailwind configuration
- Style with Tailwind CSS
- Reuse existing design tokens
- Match existing component patterns if present
- Avoid introducing ad hoc values when a token already exists

---

## 4) Resolve Durable Decisions

- Prefer existing repository conventions when they are clear
- Reuse existing Tailwind tokens, UI primitives, semantic patterns, and code structure whenever possible
- Ask the user before making any durable UI/UX or technical decision when the repository convention is not clear
- Durable decisions include new Tailwind tokens or config entries, ambiguous token mappings, new reusable abstractions, responsive behavior, interaction behavior, semantic HTML structure, and technical patterns likely to be reused
- When asking, use the ask-user-question tool and include the exact design input, closest existing convention if any, main options, and your recommended option
- Do not ask when the repository convention is clear or when the choice is local, low-impact, and easily reversible

---

## 5) Implement Component

- Build the component in React
- Style with Tailwind CSS
- Preserve layout, spacing, and visual hierarchy
- Prefer minimal structure and reusable existing primitives
- Keep the implementation responsive if the design implies it

---

## 6) Use Semantic HTML

- Prefer semantic HTML whenever the correct element is clear from the design and repository patterns
- Use landmarks, headings, lists, buttons, links, form controls, and other native elements when appropriate
- If the intended semantic structure is ambiguous, ask the user before choosing
- Do not default to generic `div` or `span` structure when a clear semantic element fits

---

## 7) Verify Fidelity

- Check structure against the Figma layout
- Check typography, spacing, and colors
- Check interactive states if shown in the design
- Check for missing assets or unsupported effects

---

# OUTPUT FORMAT

## Figma Source

- File ID:
- Node ID:
- Normalized node ID:

## Implementation Plan

- Component location:
- Tailwind tokens reused:
- Existing primitives reused:

## Result

- Implemented:
- Notes:
- Gaps or approximations:

## Validation

- Matched exactly:
- Approximated:
- Follow-up needed:
