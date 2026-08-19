# Zed-style command palette in Neovim — research

Goal: search commands by name **and** description, and surface the keybind for the selected command inline (so keybinds are learned over time). Mini-first preferred (mini.clue already surfaces leader keys; snacks is considered bloated).

## TL;DR recommendation

Use **two `mini.extra` pickers side by side** — no new plugin, no snacks/fzf/telescope:

1. `MiniExtra.pickers.keymaps()` — the *"learn the keybind"* palette. Every keymap row is `mode │ @ │ <lhs> │ desc`, so the keybind is inline by definition, and it is searched by **description** (plus `lhs`). Choosing **executes** the keymap. This is the closest thing to Zed's inline-keybind palette, because your keymaps already carry `desc` (the same `desc` mini.clue displays).
2. `MiniExtra.pickers.commands()` — the *"every Ex command"* fallback. Lists all built-in Ex commands + user commands; description is shown in the **preview** (not matched), and there is **no keybind inline**. Choosing runs the command or fills the command line.

**The gap, stated plainly:** no plugin (mini, fzf-lua, snacks, or anything else) can show "command → keybind" in one list automatically, because Neovim's command API exposes command *names + metadata* but **not** the keybinding that invokes them, and built-in Ex commands expose no human-readable description at all. That correlation only exists where *you* declared it (a keymap with a `desc`). So the honest answer is: a keymaps palette (mini.extra `keymaps`) *is* the command palette that teaches keybinds; a commands palette (`commands`) is name-only search.

---

## Core architectural finding

`nvim_get_commands()` / `getcompletion('', 'command')` return command **names** plus a metadata table (`nargs`, `bang`, `bar`, `complete`, `definition`, and `desc` **only if a user command author set one**). They do **not** return:

- a human-readable description for built-in Ex commands, and
- the keymap(s) bound to the command.

So "search by description" is impossible for built-ins from this API alone, and "inline keybind" is impossible unless the user declares keymap→command pairs themselves. This is why every candidate below splits into a `commands` picker (name search, desc in preview) and a separate `keymaps` picker (keybind + desc inline).

---

## Candidates

### 1. mini.extra (mini.nvim) — `pickers.commands()` + `pickers.keymaps()`

**`MiniExtra.pickers.commands()`**
- Lists: built-in Ex commands **and** user commands (merges `nvim_get_commands` + `nvim_buf_get_commands`; items from `getcompletion('', 'command')`). ✓
- Searches descriptions? **No** — items are plain command-name strings, no custom `match`/`show`, so mini.pick's default match runs on the name only. Description is shown only in the **preview** (`vim.inspect` of the command data, which for user commands includes `desc`). ✗ (name-only)
- Inline keybind? **No.** ✗
- Source: https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/extra.lua#L455-L477 ; doc `:h MiniExtra.pickers.commands` https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-extra.txt#L273-L281

**`MiniExtra.pickers.keymaps()`**
- Lists: all keymaps (global + buffer-local, all modes) via `nvim_get_keymap`/`nvim_buf_get_keymap`. ✓
- Searches descriptions? **Yes** — `item.text = "mode │ @ │ <lhs> │ desc"`, so fuzzy match covers `desc` and `lhs`. ✓
- Inline keybind? **Yes** — the `lhs` is the first column by design. ✓
- Choosing emulates pressing the keymap (runs it). ✓
- Source: https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/extra.lua#L1063-L1092 ; doc https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-extra.txt#L558-L567

**Maintenance:** very active. Part of mini.nvim — 9.4k stars, pushed 2026-08-15, not archived.

### 2. fzf-lua — `commands` + `keymaps`

- `commands`: lists global + buffer + built-in commands. Notably it **parses `doc/index.txt`** from the runtime to recover descriptions for built-in Ex commands (the only candidate that does this). But entries are still name strings; desc is in the **preview** only. No inline keybind.
  - Source: https://github.com/ibhagwan/fzf-lua/blob/main/lua/fzf-lua/providers/nvim.lua#L14-L114 (doc parsing at L23-L42).
- `keymaps`: columns `mode │ lhs │ desc │ rhs` with `show_desc = true, show_details = true` — keybind + desc inline, and choosing applies the keymap. Same shape as mini.extra keymaps.
  - Source: https://github.com/ibhagwan/fzf-lua/blob/main/lua/fzf-lua/providers/nvim.lua#L427 (fields `{ "mode", "lhs", "desc", "rhs" }`).
- **Maintenance:** active (4.4k stars, pushed 2026-08-13). Adds an `fzf` binary dependency, which the user is avoiding.

### 3. snacks.nvim — `Snacks.picker.commands()` + `Snacks.picker.keymaps()`

- `commands`: finder `vim_commands`. Items set `text = name`, `desc = <definition>` (only for built-ins via `script_id < 0`), preview `vim.inspect`. So **name search + a `desc` field populated by the raw definition string** (not a friendly description). No inline keybind.
  - Source: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/source/vim.lua#L6-L38 ; docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#commands
- `keymaps`: finder `vim_keymaps`, `item.text = normkey(lhs) .. " " .. text(km, {mode,lhs,rhs,desc})` — keybind + desc inline, searched. Same shape as mini.extra keymaps.
  - Source: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/source/vim.lua#L215-L264 ; docs https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#keymaps
- **Maintenance:** active (8k stars, pushed 2026-05-25). Rejected by user as bloated; functionally not better than mini.extra for this use case.

### 4. which-key.nvim (and mini.clue) — not a command palette

- which-key (and the user's mini.clue) show keybind → description as you *type keys*. That is the **reverse** direction (key → what it does), not a searchable command list. It does not search commands or show command descriptions.
- Source: https://github.com/folke/which-key.nvim ("showing available keybindings in a popup as you type").
- **Maintenance:** active but slowed (7.3k stars, last push 2025-10-28). Redundant with mini.clue already in use.

### 5. Dedicated "command palette" plugins (checked, all fail one or more requirements)

- **anoopkcn/fuzzy.nvim** — `:FuzzyCommands` lists built-in + user + plugin commands and options, showing descriptions "when Neovim exposes them". **Archived May 24 2026**, 2 stars. Not viable.
  - Source: https://github.com/anoopkcn/fuzzy.nvim (README, `:FuzzyCommands`).
- **mrjones2014/legendary.nvim** — "legend" of keymaps/commands/autocmds via `vim.ui.select`. **Archived** (pushed 2025-04-11, `archived: true`). Requires manual declaration; does not auto-list all Ex commands with descriptions.
  - Source: https://github.com/mrjones2014/legendary.nvim
- **FeiyouG/commander.nvim** — telescope-based, shows a `KEYS` component inline, but commands/keybinds are **manually registered**; no automatic listing of Ex commands. Dormant (last push 2024-06-08).
  - Source: https://github.com/FeiyouG/commander.nvim
- **hayate212/command-palette.nvim** — nui-based; searches name/description/category but only for **manually registered** commands (not Ex/plugin commands). 1 star.
  - Source: https://github.com/hayate212/command-palette.nvim
- **marnickvda/huh.nvim** — auto-discovers plugins/keymaps/commands via lazy + telescope, inline help preview. 1 star, very young.
  - Source: https://github.com/marnickvda/huh.nvim

---

## Recommendation (mini-first)

Bind these two under leader (mini.clue will surface them automatically):

```lua
vim.keymap.set('n', '<leader>,', MiniExtra.pickers.commands, { desc = 'Commands' })
vim.keymap.set('n', '<leader>;', MiniExtra.pickers.keymaps,  { desc = 'Keymaps' })
```

- Use `keymaps` as the primary "command palette" — it searches name **and** description, shows the keybind inline, and runs on `<CR>`. Keep every keymap's `desc` filled (already the convention that feeds mini.clue).
- Use `commands` for the rare unmapped Ex command; accept that it is name-search only with the description in the preview.

If true Zed parity (every Ex command + builtin description + keybind in a single list) is ever required, the only candidate that even approaches it is **fzf-lua** (it reconstructs builtin descriptions from `doc/index.txt`), but it costs an `fzf` binary dependency and still cannot show keybinds for commands it wasn't told about. A bespoke `mini.pick` source (custom `match`/`show` over a `desc`-annotated command table) is the only zero-dependency way to get both axes in one list, at the cost of maintaining that table yourself.
