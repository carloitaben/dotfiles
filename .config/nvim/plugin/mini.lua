vim.pack.add({
    { src = "https://github.com/echasnovski/mini.nvim" },
})

require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.surround").setup()
require("mini.move").setup({
    mappings = {
        -- Move visual selection in Visual mode
        left = '<',
        right = '>',
        down = 'J',
        up = 'K',
        -- Move current line in Normal mode
        line_left = '<M-h>',
        line_right = '<M-l>',
        line_down = '<M-j>',
        line_up = '<M-k>',
    },
})

-- Only trigger on <Leader>: this is a cheatsheet for our own custom
-- mappings, not a global popup for every built-in prefix key (g, z, marks,
-- registers, ...) -- those fired on nearly every normal edit and were the
-- "shows too much" noise.
local miniclue = require("mini.clue")

miniclue.setup({
    window = {
        config = {
            width = 'auto',
        },
        delay = 300,
    },
    triggers = {
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },
    },
    clues = {
        { mode = 'n', keys = '<Leader>n', desc = '+Annotations' },
        { mode = 'x', keys = '<Leader>n', desc = '+Annotations' },
    },
})

-- ⌘+s to write file
vim.keymap.set({ "n", "v", "i" }, "<D-s>", "<cmd>:w<CR>", { noremap = true, silent = true, desc = "Write file" })

-- ⌘+shift-s to write all files
vim.keymap.set({ "n", "v", "i" }, "<D-S-s>", "<cmd>:wa<CR>", { noremap = true, silent = true, desc = "Write all files" })

-- ⌘+, to open dotfiles
vim.keymap.set({ "n", "v", "i" }, "<D-,>", ":e ~/.dotfiles<CR>",
    { noremap = true, silent = true, desc = "Open dotfiles" })

-- Format
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { noremap = true, silent = true, desc = "Format" })
vim.keymap.set("x", "<leader>f", vim.lsp.buf.format, { noremap = true, silent = true, desc = "Format selection" })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Clear search highlights when pressing Esc in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Keep the cursor centered when jumping between search matches
vim.keymap.set("n", "n", "nzzzv", { noremap = true, silent = true })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true, silent = true })

-- Keep the cursor centered while scrolling half a page
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })

-- Keep the cursor centered when moving through jump history
vim.keymap.set("n", "<C-o>", "<C-o>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { noremap = true, silent = true })

-- Exit terminal mode in the builtin terminal using a shortcut that is easier to
-- discover than <C-\><C-n>
-- NOTE: This won't work in all terminal emulators
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
