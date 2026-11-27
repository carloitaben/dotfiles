# Video mode

Record a video when the point is a sequence in time: loading states, spinner order, transitions. A still frames one moment and cannot show a cascade.

`clip.py` records a hard page load, optionally followed by one click. A comparison is two clips, `before` and `after`; `/pr-shots` lays them out as a Before | After table.

Step 1 (Choose shots) and the confirmation gate of [SKILL.md](SKILL.md) apply. A video row in the plan table names the URL, the click if any, and `video` as its scope.

## Capture

Load `agent-browser`. Dev server must be running. Run from the repo root. An app behind a login: set `AGENT_BROWSER_SESSION` and `AGENT_BROWSER_RESTORE` to the signed-in session first.

```
python3 -I ~/.dotfiles/.claude/skills/shots/clip.py clip   <name> <url> [--click TEXT] [--delay MS] [--seconds N] [--note "…"]
python3 -I ~/.dotfiles/.claude/skills/shots/clip.py after  <name> <url> [same flags]
python3 -I ~/.dotfiles/.claude/skills/shots/clip.py before <name> <url> [same flags]
```

`clip` is one video. A comparison takes `after` on the working tree first, then `before` on the base files (`base.sh on` / `off` as in [COMPARE.md](COMPARE.md)). Same URL, click, delay and seconds both times.

`--delay MS` (default 400) holds every fetch and XHR response, so a loading state lasts long enough to see; local APIs answer too fast to record otherwise. `--seconds N` (default 5) is the settle time after the load and after the click: raise it when `--delay` is raised.

`--click TEXT` clicks the first link, button, label or tab whose text contains TEXT. A soft navigation (a tab switch) is a `clip` of its own with `--click`; the load that precedes it is part of the video.

After `base.sh on`, wait until the dev server serves the base files (15 to 20 seconds on a Docker bind mount) before `before`, and confirm in the sheet that the base behaviour appears.

## Look

Each run prints the video and a contact sheet at 4 frames per second. Read every sheet.

- A blank or truncated video (the run prints its length): retake.
- The difference the change makes shows in the frames: the cascade before, one wait after. A comparison whose sides look alike means the base files were not served: wait longer, restart the dev server, retake `before`.

Done when every confirmed clip has its manifest entry and both sides where it is a comparison, each read.
