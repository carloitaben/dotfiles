---
name: agent-browser
description: Debug or verify anything that runs in a browser with the agent-browser CLI. Use for frontend debugging, verifying UI changes, WebGL, and React re-render/remount investigations.
---

# agent-browser

Use the `agent-browser` CLI for anything that runs in a browser. Run `agent-browser --help` to see commands. The CLI evolves, don't assume a fixed list.

- WebGL or any feature unavailable in headless: run headed.
- Once used in the conversation, keep using it for further frontend changes without being asked.
- If a repro turns into repeated rechecking, pause and write a Playwright test instead when the project has Playwright installed.

## React re-renders / remounts

Use agent-browser's React DevTools-backed commands, not manual console.log/profiling. See [REACT.md](REACT.md) before investigating.
