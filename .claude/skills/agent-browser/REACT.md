# React debugging with agent-browser

Run `agent-browser --help` and `agent-browser react --help` for current `react ...` subcommands.

## Remount vs re-render

STRICT: to tell a genuine remount (lost fiber/state) from a normal re-render, ONLY use:

1. `react renders start`
2. trigger the action
3. `react renders stop --json`

A row with `Mounts > 0, Re-renders: 0` is a real remount.

NEVER, measure renders with counters (`console.count`/`console.log` in component bodies, temporary or not). Use ONLY `react renders start` / `stop --json`.

CAVEAT: `react renders` over-counts hard for re-render volume. One keystroke in a text field reported ~3,700 renders while a real React DevTools Profiler export of the same action showed 14 fibers. Treat its re-render and mount COUNTS as unreliable; its remount-vs-rerender signal (above) is still the only tool we use for that.

To claim "X re-renders too much" or to prove a fix, get a real DevTools export: user records in the Profiler with "Record why each component rendered while profiling" OFF (DevTools 8.0.0 crashes with it on, facebook/react#37733), exports the JSON to the Desktop (macOS blocks Downloads). Summarize with `python3 -I scripts/parse-devtools-profile.py before.zip after.json` (accepts the .zip or .json; per commit: fibers, ms, updaters, top components, plus totals). Compare before/after traces.

NEVER compare fiber IDs across separate `react tree` snapshots as remount evidence. `react tree` reassigns fresh sequential IDs on every walk regardless of whether anything remounted, so an ID changing proves nothing.

`react tree` / `react inspect` are fine for locating a fiber or reading current props/hooks, never for mount-vs-rerender proof.
