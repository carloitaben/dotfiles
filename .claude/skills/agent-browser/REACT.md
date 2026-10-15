# React debugging with agent-browser

Run `agent-browser --help` and `agent-browser react --help` for current `react ...` subcommands.

## Remount vs re-render

STRICT: to tell a genuine remount (lost fiber/state) from a normal re-render, ONLY use:

1. `react renders start`
2. trigger the action
3. `react renders stop --json`

A row with `Mounts > 0, Re-renders: 0` is a real remount.

NEVER compare fiber IDs across separate `react tree` snapshots as remount evidence. `react tree` reassigns fresh sequential IDs on every walk regardless of whether anything remounted, so an ID changing proves nothing.

`react tree` / `react inspect` are fine for locating a fiber or reading current props/hooks, never for mount-vs-rerender proof.
