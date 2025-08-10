vim.pack.add({
        { src = "https://github.com/akinsho/toggleterm.nvim" },
})

local toggleterm = require("toggleterm")

toggleterm.setup({
        open_mapping = [[<D-j>]],
        autochdir = true,
        shade_terminals = false,
        direction = "vertical"
})

local Terminal = require("toggleterm.terminal").Terminal

local lazygit  = Terminal:new({
        cmd = "lazygit",
        --   dir = "git_dir",
        hidden = true,
        direction = "float",
        on_open = function(term)
                vim.cmd("startinsert!")
                vim.keymap.set("t", "<esc>", "<esc>", { buffer = term.bufnr, nowait = true })
        end,


})

function lazygit_toggle()
        lazygit:toggle()
end

vim.keymap.set("n", "<D-S-g>", "<cmd>lua lazygit_toggle()<CR>",
        { noremap = true, silent = true, nowait = true, desc = "Open LazyGit" })
