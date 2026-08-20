if vim.env.HERDR_ENV ~= "1" then
    return
end

vim.pack.add({
    { src = "https://github.com/lmilojevicc/herdr-splits.nvim" },
})

local splits = require("herdr-splits")

splits.setup()

-- Pane navigation is herdr-native `prefix+h/j/k/l` (ctrl+b then direction),
-- mirroring nvim's ctrl+w+h/j/k/l idiom — no direct ctrl+h/j/k/l binds here.
vim.keymap.set("n", "<M-h>", splits.resize_left, { desc = "Resize left (herdr/nvim)" })
vim.keymap.set("n", "<M-j>", splits.resize_down, { desc = "Resize down (herdr/nvim)" })
vim.keymap.set("n", "<M-k>", splits.resize_up, { desc = "Resize up (herdr/nvim)" })
vim.keymap.set("n", "<M-l>", splits.resize_right, { desc = "Resize right (herdr/nvim)" })
