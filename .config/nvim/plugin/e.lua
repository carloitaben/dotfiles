vim.pack.add({
    { src = "https://github.com/folke/snacks.nvim" },
})

local snacks = require("snacks")

-- snacks.setup({
--               image = {
--         enabled = true,
--       },
--         lazygit = {
--                 enable = true
--         }
-- })

-- vim.keymap.set({ "n", "v" }, "<leader>ff", function() snacks.picker.files() end, { desc = "Files" })
-- vim.keymap.set({ "n", "v" }, "<leader>fh", function() snacks.picker.help() end, { desc = "Help pages" })
-- vim.keymap.set({ "n", "v" }, "<leader>fD", function() snacks.picker.diagnostics() end,
--         { desc = "Diagnostics" })
-- vim.keymap.set({ "n", "v" }, "<leader>fd", function() snacks.picker.diagnostics_buffer() end,
--         { desc = "Buffer diagnostics" })

-- Floating terminal
vim.keymap.set({"n", "v", "i"}, "<D-j>", function()
                snacks.terminal.toggle()
        end,
        { noremap = true, silent = true, desc = "Toggle terminal" })

-- Lazygit
vim.keymap.set({"n", "v", "i"}, "<D-S-g>", function()
                snacks.lazygit.open()
        end,
        { noremap = true, silent = true, desc = "Open LazyGit" })
vim.keymap.set({"n", "v", "i"}, "<leader>gg", function()
                snacks.open()
        end,
        { noremap = true, silent = true, desc = "Open LazyGit" })
