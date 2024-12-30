# Dotfiles

## Requirements

```sh
brew install git ripgrep stow neovim
```

### Ghostty

```sh
brew install --cask ghostty
```

### Nerd font

```sh
brew install --cask font-blex-mono-nerd-font
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