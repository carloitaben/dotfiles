vim.o.number          = true
vim.o.relativenumber  = true
vim.o.signcolumn      = "yes"
vim.o.wrap            = false
vim.o.swapfile        = false
vim.o.softtabstop     = 2
vim.o.tabstop         = 2
vim.o.smartindent     = true
vim.o.expandtab       = true
vim.o.mouse           = 'a'
vim.o.showmode        = false
vim.o.scrolloff       = 10
vim.opt.sidescrolloff = 10
vim.opt.backup        = false
vim.o.undofile        = true
vim.o.smoothscroll    = true
vim.o.cmdheight       = 0

-- Auto select the first entry but don't insert also show additional
-- information, if available
vim.o.completeopt     = 'noinsert,menuone,popup'

-- Preview substitutions live
vim.o.inccommand      = 'split'

vim.o.foldmethod      = 'indent'
vim.o.foldenable      = false

-- Case-insensitive searching unless \C or one or more capital letters in the
-- search term
vim.o.ignorecase      = true
vim.o.smartcase       = true

vim.o.splitright      = true
vim.o.splitbelow      = true

vim.g.mapleader       = " "
vim.g.maplocalleader  = " "
vim.g.have_nerd_font  = true

vim.o.winborder       = "single"
