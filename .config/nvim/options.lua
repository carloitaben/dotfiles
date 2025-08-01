vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.wrap = false
vim.o.tabstop = 2
vim.o.swapfile = false
vim.o.expandtab = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.scrolloff = 5

-- Hide command bar
vim.o.cmdheight = 0

vim.o.foldmethod = 'indent'
vim.o.foldenable = false

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.inccommand = 'split'

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
