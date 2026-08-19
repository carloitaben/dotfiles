# Grill: Zed keep/ditch inventory

Type: grilling
Status: resolved

## Question

Before the remaining feel-sensitive tickets (diff-as-buffer, search-as-buffer
prototypes) can be validated, ground "equivalent feel" in the user's actual
relationship with Zed. Produce a complete inventory of:

1. **Pain points** — what drives the migration away from Zed (the "ditch"
   list). The map never states why the migration is happening at all.
2. **Loves** — what Zed does that the user would be genuinely sad to lose
   (the "keep" list, the must-preserve bar).
3. **Don't-cares** — features present but not valued; parity is explicitly
   not worth chasing (prevents over-engineering).

Cross-check the inventory against what's already been ported (terminal dock,
Shift+Esc zoom, multicursor, mini text objects, symbol keybinds, format) to
confirm nothing was missed and each port matches a real love rather than a
habit.

## Answer

The migration's "why" and the full keep/ditch/improve inventory, in the
user's own workflow terms. This grounds "equivalent feel" for every
downstream ticket.

### Why (the driver)

State loss + agent-first workflow. The user's day: open Zed on a project,
open the right-docked terminal (~1/3 screen) to run a dev server/tests, split
that dock to also run an agent, toggle the dock off to focus, then `cmd-q`
by mistake and lose the splits + dev server + agent. Scaling to multiple
agents (research/POC work) means a fullscreen terminal crammed with splits,
toggled on/off constantly. herdr survives the fat-fingers; Zed does not. (He
deliberately keeps `cmd-q` prompt-free for fast project hopping.)

Zed-specific pains: updates break keybinds (cmd-option-o / ctrl-enter);
lazygit worktrees don't sync with Zed and are buggy; tasks run as tabs (he
wants a floating pane); snippets can't do transforms (filename → PascalCase);
not owning LSP (TS 7 double-load bug, open ticket); and local file history
(discussion #24004) still missing after years.

### Keep (must preserve feel)

- diff-as-buffer + search-as-buffer — already ticketed (02/07/08)
- right-docked terminal (cmd-j) + Shift+Esc zoom — ported
- multicursor — plugin installed, accepted as not-quite-same until nvim
  lands it natively
- snappiness — no untokenized flashes, fast treesitter/LSP; NO UI animation
  (user hates animation, wants snappy) — a perf bar, not a ticket
- LSP status/restart view → ticket 12
- command palette (search name+description, surface keybind) → ticket 13
- image previews → ticket 14
- inline git blame (gitsigns already present) — keep
- pretty/minimal — no hacky-nerdy internals in pickers → ticket 15
- nice nvim defaults / treesitter tricks — a bar, not a ticket

### Improve (nvim can beat Zed)

- local history (undotree-style timeline) → ticket 11
- snippets with transforms (React components: filename → PascalCase) →
  ticket 16
- LSP ownership (pin TS 7, no double-load) — automatic win
- lazygit as a floating pane (not a tab) → ticket 18

### Ditch

- state loss (solved by herdr), Zed update regressions (own the config),
  worktree/lazygit bugs (ticket 09), AI assistant, collab/chat/remote, git
  panel + agent panel (already out of scope), UI chrome, animation.

### Don't-care

- nothing else named; collaboration/chat/remote already ditched.

### Standing preferences (also folded into map Notes)

- mini over snacks (snacks feels bloated)
- no UI animation; snappy is the bar
- inline git blame = keep
- snippets used heavily for React components
