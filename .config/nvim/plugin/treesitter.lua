vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"html",
		"css",
		"scss",
		"javascript",
		"jsdoc",
		"typescript",
		"tsx",
		"lua",
		"luadoc",
		"luap",
		"typescript",
		"javascript",
		"bash",
		"sql",
		"vim",
		-- Config files
		"dockerfile",
		"ini",
		"json",
		"jsonc",
		"toml",
		"yaml",
		-- Treesitter
		"comment",
		"query",
		-- Markup
		"markdown",
		"markdown_inline",
		"rst",
		"vimdoc",
		"graphql",
		-- Git
		"git_config",
		"git_rebase",
		"gitattributes",
		"gitcommit",
		"gitignore",
	},
	highlight = { enable = true }
})
