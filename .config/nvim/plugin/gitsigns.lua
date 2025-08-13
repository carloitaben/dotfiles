vim.pack.add({
        { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

local gitsigns = require("gitsigns")
gitsigns.setup({
        current_line_blame = true,
        current_line_blame_opts = {
                delay = 0,
                virt_text_pos = 'right_align',
        },
        signs = {
                add          = { text = '+' },
                change       = { text = '~' },
                delete       = { text = '−' },
                topdelete    = { text = '^' },
                changedelete = { text = '*' },
                untracked    = { text = '?' },
        },
        signs_staged = {
                add          = { text = '┃' },
                change       = { text = '┃' },
                delete       = { text = '−' },
                topdelete    = { text = '−' },
                changedelete = { text = '~' },
                untracked    = { text = '┆' },
        },
})

-- Jump to next git change
vim.keymap.set("n", "]c",
        function()
                if vim.wo.diff then
                        vim.cmd.normal { ']c', bang = true }
                else
                        gitsigns.nav_hunk 'next'
                end
        end,
        { desc = "Jump to next git change" }
)

-- Jump to previous git change
vim.keymap.set("n", "[c",
        function()
                if vim.wo.diff then
                        vim.cmd.normal { '[c', bang = true }
                else
                        gitsigns.nav_hunk 'prev'
                end
        end,
        { desc = "Jump to previous git change" }
)

-- Toggle stage hunk
vim.keymap.set("v", "<leader>hs", function()
        gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
end, { desc = "Toggle stage hunk" })

vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset hunk' })
vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage buffer' })
vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset buffer' })
vim.keymap.set('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Undo stage hunk' })
vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview hunk' })
vim.keymap.set('n', '<leader>hb', gitsigns.blame_line, { desc = 'Blame line' })
vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff against index' })
vim.keymap.set('n', '<leader>hD', function()
        gitsigns.diffthis '@'
end, { desc = 'Fiff against last commit' })
