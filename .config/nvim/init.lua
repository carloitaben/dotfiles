-- Show absolute line numbers in the current window.
vim.o.number          = true
-- Show relative line numbers to make motion counts easier.
vim.o.relativenumber  = true
-- Always reserve space for signs like diagnostics and git markers.
vim.o.signcolumn      = "yes"
-- Keep long lines on a single row instead of wrapping them.
vim.o.wrap            = false
-- Use 2 spaces when pressing Tab while editing.
vim.o.softtabstop     = 2
-- Display a tab character as 2 spaces wide.
vim.o.tabstop         = 2
-- Indent and outdent by 2 spaces.
vim.o.shiftwidth      = 2
-- Copy indentation from the current line when starting a new one.
vim.o.smartindent     = true
-- Insert spaces instead of literal tab characters.
vim.o.expandtab       = true
-- Enable mouse support in all modes.
vim.o.mouse           = 'a'
-- Hide the default mode label because the statusline can show it instead.
vim.o.showmode        = false
-- Keep 10 lines visible above and below the cursor while scrolling.
vim.o.scrolloff       = 10
-- Keep 10 columns visible to the left and right when scrolling sideways.
vim.opt.sidescrolloff = 10

-- Disable backups as they just get in the way
vim.opt.backup        = false
-- Do not keep a backup file while writing changes.
vim.opt.writebackup   = false

-- Disable swap files for buffers.
vim.o.swapfile        = false

-- Persist undo history across editing sessions.
vim.o.undofile        = true

-- Animate scrolling a bit more smoothly.
vim.o.smoothscroll    = true

-- Hide the command line when it is not needed.
vim.o.cmdheight       = 0

-- Preselect the first completion item without inserting it automatically.
vim.o.completeopt     = 'noinsert,menuone,popup'


-- Limit the height of popups
vim.o.pumheight = 5


-- Preview substitutions live
vim.o.inccommand     = 'split'

-- Build folds based on indentation levels.
vim.o.foldmethod     = 'indent'
-- Start with all folds opened.
vim.o.foldenable     = false

-- Case-insensitive searching unless \C or one or more capital letters in the
-- search term
vim.o.ignorecase     = true
-- Make searches case-sensitive when the pattern includes uppercase letters.
vim.o.smartcase      = true

-- Open vertical splits to the right of the current window.
vim.o.splitright     = true
-- Open horizontal splits below the current window.
vim.o.splitbelow     = true

-- Use Space as the main leader key for custom mappings.
vim.g.mapleader      = " "
-- Use Space as the local leader key for buffer-local mappings.
vim.g.maplocalleader = " "
-- Tell plugins that Nerd Font icons are available.
vim.g.have_nerd_font = true

-- Use a single-line border around floating windows.
vim.o.winborder      = "single"
