-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

vim.pack.add({
	{ src = "https://github.com/nvim-tree/nvim-tree.lua" },
})

require("nvim-tree").setup({
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 30,
	},
	  system_open =
    -- identify OS and set OS-specific cmd with args
    vim.fn.has("mac") == 1
    and {
      cmd = "open",
      args = { "-R" },
    }
    or nil,
	renderer = {
		icons = {
			web_devicons = {
				file = {
					enable = false,
				},
				folder = {
					enable = false,
				},
			},
			git_placement = "after",
			modified_placement = "after",
			hidden_placement = "after",
			diagnostics_placement = "signcolumn",
			bookmarks_placement = "signcolumn",
			padding = {
				icon = " ",
				folder_arrow = " ",
			},
			symlink_arrow = " ➛ ",
			show = {
				file = true,
				folder = true,
				folder_arrow = false,
				git = true,
				modified = true,
				hidden = false,
				diagnostics = true,
				bookmarks = true,
			},
			glyphs = {
				default = " ",
				symlink = "",
				bookmark = "󰆤",
				modified = "M",
				hidden = "󰜌",
				folder = {
					arrow_closed = "+",
					arrow_open = "−",
					default = "+",
					open = "−",
					empty = "+",
					empty_open = "−",
					symlink = "",
					symlink_open = "",
				},
				git = {
					unstaged = "·",
					staged = "✓",
					unmerged = "",
					renamed = "➜",
					untracked = "U",
					deleted = "",
					ignored = "◌",
				},
			},
		},
	},
	filters = {
		custom = { ".git", "node_modules", ".vscode" },
		dotfiles = true,
	},
	git = {},
})

vim.api.nvim_set_keymap("n", "<C-h>", ":NvimTreeFocus<cr>", { silent = true, noremap = true })

