---
name: webreel
description: Record a polished, scripted demo of a web UI as mp4, gif or webm with webreel (animated cursor, keystroke overlay, 60fps). Use for PR, docs or changelog demos of a deterministic single-page flow. Not for bug repros or anything needing tabs, state setup or assertions: use playthrough for those.
disable-model-invocation: true
---

# webreel

[webreel](https://github.com/vercel-labs/webreel) drives its own headless Chrome from a JSON script and encodes the result with ffmpeg. Good for a clean click-through; wrong for repros (use `playthrough`).

## Setup

- `webreel --version`. If missing: `npm install -g webreel` (fnm installs globals per node version, so reinstall after a node upgrade) or prefix commands with `npx --yes`.
- First run downloads chrome-headless-shell and ffmpeg into `~/.webreel` (about 290 MB).

## Steps

1. Write `webreel.config.json` outside the repo (scratchpad). Output lands in `videos/` beside it, raw captures in `.webreel/`.
2. `webreel validate`, then `webreel preview` to watch it in a visible window, then `webreel record`.
3. Check the result: `ffprobe` the duration, extract a frame with `ffmpeg -ss <t> -i out.mp4 -frames:v 1 f.png` and look at it. Then move the file somewhere durable and `open -R` it.

```json
{
  "$schema": "https://webreel.dev/schema/v1.json",
  "baseUrl": "http://localhost:6006",
  "viewport": { "width": 1280, "height": 720 },
  "defaultDelay": 600,
  "videos": {
    "demo": {
      "url": "/iframe.html?id=components-thing--default&viewMode=story",
      "waitFor": "button",
      "steps": [
        { "action": "hover", "text": "Upload file" },
        { "action": "click", "text": "Browse library" },
        { "action": "navigate", "url": "/iframe.html?id=components-thing--disabled&viewMode=story" }
      ]
    }
  }
}
```

Actions: `pause`, `click`, `hover`, `moveTo`, `type`, `key` (`cmd+a`), `scroll`, `drag`, `select`, `wait`, `navigate`, `screenshot`. Targets are `text` or `selector`, optionally `within`. `output` can end in `.mp4`, `.gif` or `.webm`. Several videos can share one config, and `include` prepends shared steps.

## Limits (checked)

- Static pages collapse: frames are captured only when the page repaints, so `pause` on a still page adds almost no time (a static Storybook story came out 0.9s long; a page that kept updating came out the full 7s). Choose flows with motion (navigation, typing, transitions, spinners) or accept a short clip.
- One page, no tabs, no JS step, no captions, no file-upload action.
- Its own Chrome has no login and no storage from your browser. Log in with `type` steps, or demo something that needs no auth (Storybook, a public page).
