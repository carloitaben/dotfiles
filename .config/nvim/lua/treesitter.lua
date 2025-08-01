vim.pack.add({
        { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

require("nvim-treesitter.configs").setup({
        ensure_installed = { "typescript", "javascript" },
        highlight = { enable = true }
})
