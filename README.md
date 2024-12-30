# Dotfiles

## Requirements

```sh
brew install git ripgrep stow
```

## Set up

```sh
brew install stow
```

```sh
git clone https://github.com/carloitaben/dotfiles.git "${XDG_CONFIG_HOME:-$HOME/.dotfiles}"
```

```sh
stow .
```
