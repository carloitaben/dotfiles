# Decide: herdr + worktree session workflow

Type: grilling
Status: open
Blocked by: 01

## Question

Two distinct worktree-creation paths need a decision, not one:

1. **Agent-driven**: an agent is told "use a worktree for this." Research
   (see [[01-herdr-worktree-patterns]]) already covers this — the agent can
   just call `herdr worktree create` directly, optionally backed by
   `herdr-plus` for auto-layout.
2. **lazygit-driven** (the user's actual original concern): lazygit has its
   own "Worktrees" view for creating/switching worktrees. That's a plain
   `git worktree` operation lazygit knows nothing about herdr — switching
   there does NOT move you to a different herdr tab/session, and does not
   change any pane's cwd. You'd stay in the same lazygit pane, now pointed
   at a worktree living elsewhere on disk, while herdr's own notion of
   "where you are" hasn't moved.

Decide: should switching/creating a worktree via lazygit's UI be wired to
also open/move-to the corresponding herdr tab — e.g. via lazygit's custom
commands feature shelling out to `herdr worktree open <path>` on selecting a
worktree — or is lazygit's worktree view out of the picture entirely (only
ever create/switch worktrees through herdr/the agent, treat lazygit as
branch/commit/diff UI only)? Implement whichever is chosen.

## Progress notes (paused mid-session, not resolved)

Carlo's stated concern, in his words: he doesn't care about agent-driven
worktree creation (that's basically settled by ticket 01/02) — the live
worry is specifically the **lazygit UI** flow. Today's existing lazygit
custom commands (`.config/lazygit/config.yml`) already create worktrees via
raw `git worktree add`, bypassing herdr entirely — confirmed, not
hypothetical. His bad-UX example: editing in nvim on worktree A's pane,
switching to worktree B via lazygit's worktree view, and "nothing happens" —
he ends up in a stale/wrong state. He explicitly does NOT yet have an opinion
on the right mental model (one-worktree-one-pane or not) and wants to see
what the herdr/lazygit community actually does before deciding, rather than
inventing a UX from scratch.

**Facts gathered locally this session** (see herdr CLI): `herdr worktree
create --path <PATH> --branch <NAME> --base <REF> --focus/--no-focus` and
`herdr worktree open --path <PATH> --focus/--no-focus` both exist and are
scriptable — confirms ticket 01's finding that shelling out from a lazygit
custom command is viable, just not yet whether/how it should be wired.

**Research commissioned and completed**: full findings written to
`.scratch/nvim-herdr-migration/research/lazygit-herdr-worktree-integration.md`
on branch `research/lazygit-herdr-worktree-integration` (commit `62a3951`).
Read that file for citations; gist:

- herdr's own convention is "worktree = one workspace," with tab/pane layout
  *inside* that workspace left to config (two independent plugins,
  herdr-sessionizer and herdr-kiosk, both do config-driven layout on
  worktree create/open). No "many panes per worktree" alternative found
  anywhere.
- lazygit itself ships zero multiplexer integration for its Worktrees view —
  it's 100% third-party config. The dominant tmux-side convention, found
  verbatim across 6+ unrelated dotfiles repos, is a `worktrees`-context
  custom command running `sesh connect '{{.SelectedWorktree.Path}}'`.
- Two herdr-specific answers exist in the wild:
  1. `AlessioRocco/dotfiles` binds worktree-select to `wt switch` (worktrunk,
     which does the herdr-side pane bootstrap), then kills its own lazygit
     popup process.
  2. `andresgutgon/dotfiles` does NOT open a new pane at all — it
     remote-controls the *already-running* Neovim via `nvim --server
     --remote-expr` calling a `WorktreeSwitch` command from the
     `worktrees.nvim` plugin, which changes the existing nvim's cwd/buffers
     in place. This is a direct, working answer to Carlo's exact "what
     happens to the pane I was editing in" complaint: the pane doesn't move
     or close, the program inside it reloads state at the new path.
- On "what happens to the pane you switch away from" generally: tmux-era
  tools (workmux, muxtree, worktree-mux) default to *leaving the old
  window/session running*, relying on tmux's native persistence. The one
  herdr-native tool found that addresses it explicitly
  (`Yassimba/loom`'s `pi-herdr-worktree`) does the **opposite** by
  default — closes the old pane after opening the new one (`--no-close-pane`
  to opt out) — and this exact behavior is copy-pasted into a dozen+ other
  dotfiles repos, so it's a real if narrow convention, not one person's
  taste.
- No source addresses the *exact* combined scenario (lazygit's own UI +
  sibling nvim pane) — confirmed gap, not just an oversight in this
  research.

**Not yet decided — pick up here next session:**
1. Which shape fits Carlo's nvim/herdr setup: (a) `worktrees.nvim`-style
   in-place nvim retarget (no new pane, existing editor reloads at new
   path), (b) worktrunk/`wt switch`-style new-pane-plus-close-old-pane, or
   (c) something else. Given the Destination says nvim stays "a pure
   editor" and herdr owns all process/pane lifecycle, option (a) sits a
   little oddly (nvim reaching into worktree-switching itself) — worth
   grilling directly rather than assuming.
2. Once the shape is picked: which lazygit actions get rewired (create-only
   vs. also switch — see the three-option breakdown that was mid-discussion
   when this session paused: replace the `N` custom commands only /
   add a new "open in herdr" key alongside lazygit's built-in switch /
   override lazygit's built-in switch key entirely).
3. Whether `herdr worktree create`'s existing `--focus` flag is enough, or
   whether creation should also trigger whatever "reflect in nvim" mechanism
   is picked in (1).
