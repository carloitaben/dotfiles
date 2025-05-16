# Dotfiles

## Steps

1. Clone the repo.

```sh
git clone https://github.com/carloitaben/dotfiles.git "${XDG_CONFIG_HOME:-$HOME/.dotfiles}"
```

2. Install [Homebrew](https://brew.sh/).

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Run the Homebrew Bundle file.

```sh
brew bundle --file=~/.dotfiles/Brewfile
```

4. Run `stow`.

```sh
stow .
```
