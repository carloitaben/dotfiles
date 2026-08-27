# Data file: known name -> command that prints a zsh completion script to stdout.
# Read by bin/sync-completions (to regenerate the cache) and bin/discover-completions
# (to know what's already tracked, and to append newly found tools here).
typeset -gA COMPLETION_GENERATORS=(
  fnm      "fnm completions --shell zsh"
  gh       "gh completion -s zsh"
  herdr    "herdr completion zsh"
  lazygit  "lazygit completion zsh"
  luarocks "luarocks completion zsh"
  pnpm     "pnpm completion zsh"
  railway  "railway completion zsh"
)
