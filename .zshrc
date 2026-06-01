# Tell zsh where your config lives (default is $HOME, but explicit is better)
export ZDOTDIR=$HOME

# Needed for lazygit to find its global config
export XDG_CONFIG_HOME="$HOME/.config"

# Prompt
PROMPT='%F{white}%~ %F{yellow}⏺%f '

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt SHARE_HISTORY        # new sessions see commands from currently-open sessions
setopt HIST_IGNORE_ALL_DUPS # only keep the most recent occurrence of a duplicate
setopt HIST_IGNORE_SPACE    # commands starting with space are not stored

# Node version manager
export NVM_LAZY_LOAD=true
source ~/.oh-my-zsh/custom/plugins/zsh-nvm/zsh-nvm.plugin.zsh

# pnpm tab completions
source ~/.oh-my-zsh/custom/plugins/pnpm-shell-completion/pnpm-shell-completion.plugin.zsh

# Completions engine
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Syntax highlighting (must come before autosuggestions)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='zed --wait'
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

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

export PATH="$HOME/.local/bin:$PATH"
