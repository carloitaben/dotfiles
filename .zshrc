# Tell zsh where your config lives (default is $HOME, but explicit is better)
export ZDOTDIR=$HOME

# Needed for lazygit to find its global config
export XDG_CONFIG_HOME="$HOME/.config"

# Prompt
PROMPT='%F{white}%~ %F{yellow}⏺%f '

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY        # new sessions see commands from currently-open sessions
setopt HIST_IGNORE_ALL_DUPS # only keep the most recent occurrence of a duplicate
setopt HIST_IGNORE_SPACE    # commands starting with space are not stored

# Prefix history search — type a partial command, up/down cycles matches only
zmodload zsh/terminfo
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "$terminfo[kcuu1]" history-beginning-search-backward-end
bindkey "$terminfo[kcud1]" history-beginning-search-forward-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# fnm (node version manager) — auto-switches on cd, mirrors old zsh-nvm behavior
eval "$(fnm env --use-on-cd --shell zsh)"

# Completions engine — must run before anything that calls compdef
# -u skips the security check (Homebrew dirs are group-writable by design)
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit -u
else
  compinit -Cu
fi

# Syntax highlighting (must come before autosuggestions)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export TERMINAL='ghostty'
export BROWSER=open
export OPENCODE_EXPERIMENTAL=1

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# zoxide (interactive only — non-interactive shells sourcing this file, e.g. tool
# subprocesses, would otherwise trip zoxide's doctor check with a spurious warning:
# https://github.com/ajeetdsouza/zoxide/issues/1208)
if [[ -o interactive ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.dotfiles/bin:$PATH"

# Herdr panes share one persistent Neovim instance. Closing a visible client
# only detaches it, so buffers, undo history, and LSP clients stay warm.
nvim() {
  if [[ ${HERDR_ENV:-} != 1 ]]; then
    command nvim "$@"
    return
  fi

  case "${1:-}" in
    -h|--help|-v|--version|--headless|--clean|--listen|--server|--remote*|-l|-es|-Es)
      command nvim "$@"
      return
      ;;
  esac

  local runtime_dir="${XDG_RUNTIME_DIR:-${TMPDIR%/}}"
  local socket="$runtime_dir/nvim-herdr-${UID}.sock"

  if ! command nvim --headless --server "$socket" --remote-expr '1' >/dev/null 2>&1; then
    nvim-herdr-start || return
  fi

  if (( $# )); then
    # The server resolves relative paths against its own cwd, not ours
    # (it's one shared process across every herdr workspace), so
    # absolutize file args here before sending them over --remote.
    local -a resolved=()
    local arg
    for arg in "$@"; do
      if [[ $arg == -* ]]; then
        resolved+=("$arg")
      else
        resolved+=("${arg:A}")
      fi
    done
    command nvim --headless --server "$socket" --remote "${resolved[@]}" || return
  fi

  command nvim --headless --server "$socket" --remote-expr \
    "luaeval(\"HerdrAgentState and HerdrAgentState.attach(...)\", '$HERDR_PANE_ID')" \
    >/dev/null 2>&1
  command nvim --server "$socket" --remote-ui
  command nvim --headless --server "$socket" --remote-expr \
    "luaeval(\"HerdrAgentState and HerdrAgentState.detach()\")" \
    >/dev/null 2>&1
}

# Stop the shared Neovim server alongside `herdr server stop`, so it doesn't
# linger as an orphaned process once herdr itself is gone.
herdr() {
  command herdr "$@"
  local exit_status=$?
  if [[ "$1" == "server" && "$2" == "stop" ]]; then
    nvim-herdr-stop
  fi
  return $exit_status
}

# re-sync completions whenever brew installs/upgrades something
brew() {
  command brew "$@"
  local status=$?
  case "$1" in
    install|reinstall|upgrade|bundle) sync-completions ;;
  esac
  return $status
}

# fzf key bindings (ctrl-r fuzzy history, ctrl-t fuzzy file search)
[ -s /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
