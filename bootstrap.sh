#!/bin/sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "🌀 Installing Homebrew packages"
brew bundle --file="$DOTFILES_DIR/Brewfile"

echo "🌀 Installing npm global packages"
npm install -g \
  @mariozechner/pi-coding-agent \
  corepack \
  opensrc

echo "🎉"
