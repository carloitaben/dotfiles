# Dotfiles

## Steps

1. Install [Homebrew](https://brew.sh/).

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install [git](https://git-scm.com/install/mac).

3. Clone the repo.

```sh
git clone https://github.com/carloitaben/dotfiles.git "${XDG_CONFIG_HOME:-$HOME/.dotfiles}"
```

4. Run the bootstrap script.

```sh
sh ~/.dotfiles/bootstrap.sh
```

5. Run `stow`.

```sh
stow .
```

## OpenCode worker model

The `explore` and `implement` subagents use the model in `~/.config/opencode/worker-model`.

```sh
# GPT-6 Luna
echo 'opencode-go/gpt-6-luna' > ~/.config/opencode/worker-model

# DeepSeek
echo 'opencode-go/deepseek-v4.1-flash' > ~/.config/opencode/worker-model

# Check the current model
cat ~/.config/opencode/worker-model
```

Run `/reload` in OpenCode if the change doesn't take effect immediately.

## Godot

See [godot/README.md](godot/README.md) for the GodotVim + GDScript formatter
setup. Run `godot-setup .` inside a project to install everything; it also
enables Add Type Hints and the UNTYPED_DECLARATION warning.
