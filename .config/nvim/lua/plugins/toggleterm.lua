vim.pack.add({
        { src = "https://github.com/akinsho/toggleterm.nvim" },
})

local toggleterm = require("toggleterm")

toggleterm.setup({
        open_mapping = [[<D-j>]],
        autochdir = true,
        shade_terminals = false
})

local Terminal = require("toggleterm.terminal").Terminal

-- local lazygit = terminal:new {
--   cmd = "lazygit",
--   dir = "git_dir",
--   direction = "float",
--   float_opts = {
--     border = "shadow",
--     winblend = 5,
--   },
--   -- function to run on opening the terminal
--   on_open = function(term)
--     vim.cmd "startinsert!"
--     vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
--   end,
-- }
local lazygit  = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        -- 90% width and height
        -- float_opts = {
        --         width = math.floor(vim.o.columns * 0.9),
        --         height = math.floor(vim.o.lines * 0.9),
        -- },
        on_open = function(term)
                vim.keymap.set("t", "<esc>", "<esc>", { buffer = term.bufnr, nowait = true })
        end,


})

function lazygit_toggle()
        lazygit:toggle()
end

vim.keymap.set("n", "<D-S-g>", "<cmd>lua lazygit_toggle()<CR>",
        { noremap = true, silent = true, nowait = true, desc = "Open LazyGit" })
-- vim.api.nvim_set_keymap("n", "<tab>", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true, nowait= true})


-- vim.keymap.set("n", "<D-j>", toggleterm.,
--     { silent = true, noremap = true, desc = "File Explorer: Focus" })
--
-- vim.keymap.set("n", "<D-b>", ":NvimTreeToggle<CR>", { silent = true, noremap = true, desc = "File Explorer: Toggle" })
