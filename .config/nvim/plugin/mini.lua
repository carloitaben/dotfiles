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

-- local miniclue = require("mini.clue")

-- miniclue.setup({
--     window = {
--         config = {
--             width = 'auto',
--         },
--         delay = 0
--     },
--     triggers = {
--         -- Leader triggers
--         { mode = 'n', keys = '<Leader>' },
--         { mode = 'x', keys = '<Leader>' },

--         -- Built-in completion
--         { mode = 'i', keys = '<C-x>' },

--         -- `g` key
--         { mode = 'n', keys = 'g' },
--         { mode = 'x', keys = 'g' },

--         -- Marks
--         { mode = 'n', keys = "'" },
--         { mode = 'n', keys = '`' },
--         { mode = 'x', keys = "'" },
--         { mode = 'x', keys = '`' },

--         -- Registers
--         { mode = 'n', keys = '"' },
--         { mode = 'x', keys = '"' },
--         { mode = 'i', keys = '<C-r>' },
--         { mode = 'c', keys = '<C-r>' },

--         -- Window commands
--         { mode = 'n', keys = '<C-w>' },

--         -- `z` key
--         { mode = 'n', keys = 'z' },
--         { mode = 'x', keys = 'z' },

--         -- Bracketed
--         { mode = 'n', keys = '[' },
--         { mode = 'n', keys = ']' },

--         -- Surrounds
--         { mode = "n", keys = "s" },

--         -- Built-in completion
--         { mode = "i", keys = "<C-x>" },

--     },

--     clues = {
--         { mode = "n", keys = "<Leader>s", desc = "+Search" },
--         miniclue.gen_clues.builtin_completion(),
--         miniclue.gen_clues.g(),
--         miniclue.gen_clues.marks(),
--         miniclue.gen_clues.registers(),
--         miniclue.gen_clues.windows(),
--         miniclue.gen_clues.z(),
--     },
-- })

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
