---
description: Use the Figma MCP to implement a Figma design as a React component
agent: build
subtask: true
---

You are implementing a Figma design as a React component.

Design to implement:
$ARGUMENTS

If no Figma link or node reference is provided, stop and ask the user to provide one.

Examples:
- `https://www.figma.com/file/...?...&node-id=1-2`
- `fileId: abc123, node-id: 12-34`

IMPORTANT: Convert node IDs from dash-separated to colon-separated before using the Figma MCP.

Before:
?node-id=1-2

After:
?node-id=1:2

Use the Figma MCP server to get design tokens and layout information.

Requirements:
- Style with Tailwind CSS. Read the Tailwind configuration file to ensure you use the existing design tokens

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
- Reuse existing design tokens
- Match existing component patterns if present
- Avoid introducing ad hoc values when a token already exists

---

## 4) Implement Component

- Build the component in React
- Style with Tailwind CSS
- Preserve layout, spacing, and visual hierarchy
- Prefer minimal structure and reusable existing primitives
- Keep the implementation responsive if the design implies it

---

## 5) Verify Fidelity

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
