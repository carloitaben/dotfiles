# Task: remove nvim-tree

Type: task
Status: resolved

## Question

Remove `nvim-tree.lua` and its plugin registration from `.config/nvim/` —
confirmed leftover, `oil.nvim` is the file explorer going forward.

## Answer

Deleted `.config/nvim/plugin/nvim-tree.lua` (the file was already 100%
commented-out — no live `vim.pack.add`, no active `require`, no keymaps
bound). Removed the installed plugin from disk with `vim.pack.del({
'nvim-tree.lua' })`, which also dropped it from `nvim-pack-lock.json`
(`kyazdani42/nvim-tree.lua`). Note: the lockfile must not be edited by hand
(`:help vim.pack` says "Corrupted data for installed plugins is repaired")
— `vim.pack.del` is the correct removal path, and is what updated the lock.

Verified: JSON still valid, no remaining `nvim-tree` references (the grep
hits are all `nvim-treesitter`, a separate still-used plugin), plugin gone
from `site/pack/core/opt/`. File explorer is already fully oil.nvim — it
owns the `<D-S-e>` keybind in `plugin/oil.lua:51`.
