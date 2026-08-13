if vim.env.HERDR_ENV ~= "1" then
    return
end

vim.pack.add({
    { src = "https://github.com/lmilojevicc/herdr-splits.nvim" },
})

local splits = require("herdr-splits")

splits.setup()

vim.keymap.set("n", "<C-h>", splits.move_cursor_left, { desc = "Navigate left (herdr/nvim)" })
vim.keymap.set("n", "<C-j>", splits.move_cursor_down, { desc = "Navigate down (herdr/nvim)" })
vim.keymap.set("n", "<C-k>", splits.move_cursor_up, { desc = "Navigate up (herdr/nvim)" })
vim.keymap.set("n", "<C-l>", splits.move_cursor_right, { desc = "Navigate right (herdr/nvim)" })

vim.keymap.set("n", "<M-h>", splits.resize_left, { desc = "Resize left (herdr/nvim)" })
vim.keymap.set("n", "<M-j>", splits.resize_down, { desc = "Resize down (herdr/nvim)" })
vim.keymap.set("n", "<M-k>", splits.resize_up, { desc = "Resize up (herdr/nvim)" })
vim.keymap.set("n", "<M-l>", splits.resize_right, { desc = "Resize right (herdr/nvim)" })
