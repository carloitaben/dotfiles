#!/bin/sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# OpenCode owns this runtime directory. Remove links from an older dotfiles setup.
for file in .gitignore bun.lock package-lock.json package.json; do
  path="$HOME/.opencode/$file"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "../.dotfiles/.opencode/$file" ]; then
    rm "$path"
  fi
done

echo "🌀 Installing Homebrew packages"
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo "🌀 Configuring global git hooks"
git config --global core.hooksPath "$HOME/.config/git-hooks"

echo "🌀 Installing npm global packages"
npm install -g \
  @mariozechner/pi-coding-agent \
  corepack \
  opensrc \
  agentation-mcp

corepack enable

echo "🌀 Installing herdr plugins"
herdr plugin install lmilojevicc/herdr-splits.nvim --yes
herdr plugin install usrivastava92/herdr-wakeup/plugin --ref v0.1.0 --yes
herdr plugin link "$DOTFILES_DIR/.config/herdr/plugins/recent-projects"
herdr plugin link "$DOTFILES_DIR/.config/herdr/plugins/nvim-server"

echo "🎉"
