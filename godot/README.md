# GodotVim setup

This directory contains the reusable pieces for setting up Vim-style editing
and typed GDScript in Godot:

- `godot-vimrc` — the `.godot-vimrc` template copied into each project
- `godotvim_formatter_bridge/` — a tiny editor plugin that lets `space f` call
  the GDQuest GDScript Formatter

The scripts live in `~/.dotfiles/bin`:

```sh
godot-setup          # runs every step below, in filename order
godot-vim-init       # GodotVim, formatter, bridge, .godot-vimrc
godot-settings-init  # Add Type Hints + UNTYPED_DECLARATION
```

## Requirements

- Godot 4.5 or newer
- `python3`, `curl`, and `unzip`
- macOS or Linux for the automatic formatter-binary install

## Quick start

From a Godot project directory:

```sh
godot-setup .
```

Or point it at another project:

```sh
godot-setup ~/godot-project
```

Then reload Godot:

```text
Project → Reload Current Project
```

Open a GDScript file. You should see the block cursor and the Vim mode
indicator.

`godot-setup` only takes a project directory. Run a step directly when you need
its options, for example:

```sh
godot-vim-init . --force-vimrc
GODOT_UNTYPED_DECLARATION=error godot-settings-init .
```

## What the setup does

For the target project it:

1. Enables **Text Editor → Completion → Add Type Hints** (global editor
   setting).
2. Sets `debug/gdscript/warnings/untyped_declaration` to Warn in
   `project.godot`.
3. Copies `addons/godot_vim` (GodotVim).
4. Copies `addons/GDQuest_GDScript_formatter` (the formatter).
5. Copies `addons/godotvim_formatter_bridge` (the formatter bridge).
6. Creates `.godot-vimrc` if the project doesn't already have one.
7. Adds the three plugins to `[editor_plugins]` in `project.godot`, preserving
   any plugins already enabled.
8. Ensures the GDQuest formatter binary exists in Godot's cache.

Every step is idempotent. Running the setup again only reports what is already
in place.

## Editor and project settings

`godot-settings-init` writes two settings:

| Setting | Scope | Value |
| --- | --- | --- |
| `text_editor/completion/add_type_hints` | Global editor settings | `true` |
| `debug/gdscript/warnings/untyped_declaration` | Per project (`project.godot`) | `1` (Warn) |

`Add Type Hints` makes autocompletion insert type annotations. The warning is
per project because Godot has no global default for it; this is why the setup is
run per project.

Environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `GODOT_UNTYPED_DECLARATION` | `Warn` | `Ignore`, `Warn`, `Error`, or `0`/`1`/`2` |
| `GODOT_EDITOR_SETTINGS` | all found | Path to one `editor_settings-*.tres` |

The editor settings file is global:

- macOS: `~/Library/Application Support/Godot/editor_settings-4.*.tres`
- Linux: `${XDG_CONFIG_HOME:-~/.config}/godot/editor_settings-4.*.tres`

Quit Godot before running the script. Godot keeps editor settings in memory and
overwrites the file on exit. If no settings file exists yet, launch Godot once
and re-run.

## Options

```text
godot-vim-init [PROJECT_DIR] [--force] [--force-vimrc]
godot-settings-init [PROJECT_DIR]
godot-setup [PROJECT_DIR]

  PROJECT_DIR    Godot project directory (default: current directory)
  --force        Replace existing addons in the project
  --force-vimrc  Replace an existing .godot-vimrc in the project
```

Existing `.godot-vimrc` files are **not** overwritten by default, so per-project
customizations survive. Use `--force-vimrc` when you want to reset a project to
the template.

## GodotVim environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `GODOT_VIM_HOME` | `~/.local/share/godot-vim` | Cache root for addons and the formatter binary |
| `GODOT_VIM_SRC` | unset | Path to an `addons/godot_vim` folder to copy from |
| `GODOT_VIM_CACHE` | `$GODOT_VIM_HOME/addons/godot_vim` | Override the GodotVim cache path |

If an addon or the formatter binary is missing from the cache, the installer
downloads the current release from GitHub. For GodotVim it may first reuse a
copy from an existing local project.

## Where things live

Cache:

```text
~/.local/share/godot-vim/
├── addons/
│   ├── godot_vim/
│   └── GDQuest_GDScript_formatter/
└── bin/
    └── gdscript-formatter
```

The formatter binary is installed into Godot's editor cache, because that is
where the formatter addon and the bridge look for it:

- macOS: `~/Library/Caches/Godot/gdquest/gdscript-formatter`
- Linux: `${XDG_CACHE_HOME:-~/.cache}/godot/gdquest/gdscript-formatter`

The binary is global; the addons are per-project.

## Default mappings

The template sets `space` as the leader and includes:

| Keys | Action |
| --- | --- |
| `space f` | Format the current script |
| `g h` | Show the symbol tooltip at the caret |
| `F2` | Open Replace in Files (rename workaround) |
| `ctrl-w h/j/k/l` | Focus the panel left/down/up/right |
| `J` / `K` (visual) | Move the selected lines down/up, keeping the selection |
| `>` / `<` / `=` (visual) | Indent / outdent / auto-indent, keeping the selection |
| `g o` | Jump to the start of the file (`gg0`) |
| `H` / `L` | Previous / next script |

`Ctrl+Alt+I` also formats directly; that is the GDQuest formatter's own
shortcut.

### Rename

Godot's built-in script editor does not expose semantic symbol rename, even
though the GDScript language server supports it. `F2` opens **Replace in
Files** as a workaround. Use **Whole Words** in that dialog to avoid partial
matches. It is textual, not semantic.

## Customizing

Edit the template:

```sh
~/.dotfiles/godot/godot-vimrc
```

New projects get the updated template. Existing projects keep their current
`.godot-vimrc`; update one with:

```sh
godot-vim-init ~/godot-project --force-vimrc
```

The formatter bridge is at:

```sh
~/.dotfiles/godot/godotvim_formatter_bridge/
```

Use `--force` to copy an updated bridge into an existing project.

To add a new mapping, put it in the template and reload Godot, or edit the
project's `.godot-vimrc` directly and run `:source` in GodotVim.

## Adding a setup step

`godot-setup` runs every `bin/godot-*-init` script in filename order. To extend
the setup, add a script with that name and the executable bit:

```sh
~/.dotfiles/bin/godot-mytool-init
```

Each step receives the project directory as its only argument. Name the script
so the filename order matches the order you want (for example
`godot-10-mytool-init`). Steps should be idempotent.

## Updating the addons

The cache is the source of truth:

```text
~/.local/share/godot-vim/addons/
├── godot_vim/
└── GDQuest_GDScript_formatter/
```

Replace a cached addon folder with a newer version, then push it into a project:

```sh
godot-vim-init ~/godot-project --force
```

The formatter binary is cached separately:

```text
~/.local/share/godot-vim/bin/gdscript-formatter
```

Replace it with a newer binary, then rerun the installer. The installer copies
it into Godot's editor cache automatically.

## Troubleshooting

**GodotVim doesn't appear in a project**

The addon is per-project. Check:

- `addons/godot_vim/` exists in the project
- `project.godot` has `res://addons/godot_vim/plugin.cfg` under
  `[editor_plugins]`
- **Project → Project Settings → Plugins** shows GodotVim enabled

The global **Godot Vim → Enabled** editor setting only controls a plugin that is
already loaded; it does not install the addon into a project.

**`space f` does nothing**

Check that:

- the current tab is a GDScript file
- the script editor has focus
- **GDQuest GDScript Formatter** is enabled in Project Settings → Plugins
- `~/Library/Caches/Godot/gdquest/gdscript-formatter` exists and is executable

If GDQuest's setup window appears on first load, you can close it; the binary is
already installed by the bootstrap script.

**Plugin changes don't take effect**

Reload the project:

```text
Project → Reload Current Project
```

**Add Type Hints or UNTYPED_DECLARATION doesn't apply**

- Quit Godot before running `godot-settings-init`; Godot rewrites the editor
  settings file on exit.
- **Add Type Hints** is a global editor setting; the warning is per project.
  Check `project.godot` has `gdscript/warnings/untyped_declaration=1` under
  `[debug]`.
- If no `editor_settings-*.tres` exists yet, launch Godot once and re-run.

**A mapping is ignored**

The project `.godot-vimrc` is sandboxed by default. If a mapping gets stripped,
check the GodotVim status/output for the reason. You can set
**Editor Settings → Godot Vim → Security → Project Vimrc** to `Trusted` for your
own projects, but that is a global security setting.

## Uninstalling from a project

Remove the three addon folders, delete `.godot-vimrc`, and remove the matching
entries from `[editor_plugins]` in `project.godot`:

```text
addons/godot_vim
addons/GDQuest_GDScript_formatter
addons/godotvim_formatter_bridge
```

The `gdscript/warnings/untyped_declaration` entry under `[debug]` in
`project.godot` is left in place; remove it to restore Godot's default
(Ignore).
