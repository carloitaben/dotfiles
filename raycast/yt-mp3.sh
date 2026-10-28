#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Download YouTube MP3
# @raycast.mode compact
# @raycast.icon 🎵
# @raycast.argument1 { "type": "text", "placeholder": "YouTube URL", "optional": true }

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
"$HOME/.dotfiles/bin/yt-mp3" "${1:-}"
