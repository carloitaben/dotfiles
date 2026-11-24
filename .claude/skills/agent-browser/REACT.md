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

To claim "X re-renders too much" or to prove a fix, get a real DevTools export, recorded with "Record why each component rendered while profiling" OFF (DevTools 8.0.0 crashes with it on, facebook/react#37733) and saved to the Desktop (macOS blocks Downloads). Summarize with `python3 -I scripts/parse-devtools-profile.py before.zip after.json` (accepts the .zip or .json; per commit: fibers, ms, updaters, top components, plus totals). Compare before/after traces.

Record it yourself with `scripts/record-react-profile.sh <url> [field-label]`: it drives the user's real Chrome (React DevTools extension installed) through agent-desktop, focuses then blurs the field, saves the export to the Desktop and runs the parser. Read the script header for prerequisites. The run takes ~40s of physical input, so ask the user to hand over the machine first, and have the page already logged in in Chrome. When a dev-server trace looks wrong, re-record on a production-like build with the profiling React (alias `react-dom/client` to `react-dom/profiling`, `minify: false`): React's dev build deep-reads changed props for its Performance tracks, which can flag every key of RHF's `formState` proxy as subscribed.

NEVER compare fiber IDs across separate `react tree` snapshots as remount evidence. `react tree` reassigns fresh sequential IDs on every walk regardless of whether anything remounted, so an ID changing proves nothing.

`react tree` / `react inspect` are fine for locating a fiber or reading current props/hooks, never for mount-vs-rerender proof.
