-- Neovim has no built-in detection for .env files. Treat them as sh so
-- treesitter highlighting and bashls both apply.
vim.filetype.add({
    pattern = {
        ["%.env$"] = "sh",
        ["%.env%.[%w_.-]+$"] = "sh",
    },
})
