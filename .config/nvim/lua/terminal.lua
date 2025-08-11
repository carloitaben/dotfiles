vim.pack.add({
        { src = "https://github.com/folke/snacks.nvim" },
})

local terminal = require("snacks.terminal")
local lazygit = require("snacks.lazygit")

-- Floating terminal
vim.keymap.set("", "<D-j>", function()
                terminal.toggle()
        end,
        { noremap = true, silent = true, desc = "Toggle terminal" })

-- Lazygit
vim.keymap.set("", "<D-S-g>", function()
                lazygit.open()
        end,
        { noremap = true, silent = true, desc = "Open LazyGit" })
vim.keymap.set("", "<leader>gg", function()
                lazygit.open()
        end,
        { noremap = true, silent = true, desc = "Open LazyGit" })
