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

## Godot

See [godot/README.md](godot/README.md) for the GodotVim + GDScript formatter
setup. Run `godot-setup .` inside a project to install everything; it also
enables Add Type Hints and the UNTYPED_DECLARATION warning.
