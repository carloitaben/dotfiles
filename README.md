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

4. Run the Homebrew Bundle file.

```sh
brew bundle --file=~/.dotfiles/Brewfile
```

5. Run `stow`.

```sh
stow .
```
