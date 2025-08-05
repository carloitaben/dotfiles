-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

vim.pack.add({
	{ src = "https://github.com/nvim-tree/nvim-tree.lua" },
})

local api = require("nvim-tree.api")

require("nvim-tree").setup({
    on_attach = function (bufnr)
        local opts = { buffer = bufnr }
        api.config.mappings.default_on_attach(bufnr)
        -- function for left to assign to keybindings
        local lefty = function ()
            local node_at_cursor = api.tree.get_node_under_cursor()
            -- if it's a node and it's open, close
            if node_at_cursor.nodes and node_at_cursor.open then
                api.node.open.edit()
            -- else left jumps up to parent
            else
                api.node.navigate.parent()
            end
        end
        -- function for right to assign to keybindings
        local righty = function ()
            local node_at_cursor = api.tree.get_node_under_cursor()
            -- if it's a closed node, open it
            if node_at_cursor.nodes and not node_at_cursor.open then
                api.node.open.edit()
            end
        end
        local toggle = function ()
            local node_at_cursor = api.tree.get_node_under_cursor()

if node_at_cursor.nodes then
    if node_at_cursor.open then
        api.node.open.edit()  -- Assuming you want to close the node
    else
        api.node.open.edit()
    end
end
        end
        vim.keymap.set("n", "h", lefty , opts )
        vim.keymap.set("n", "<Left>", lefty , opts )
        vim.keymap.set("n", "<Right>", righty , opts )
        vim.keymap.set("n", "<Space>", toggle , opts )
        vim.keymap.set("n", "l", righty , opts )
    end,
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 40,
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


vim.api.nvim_set_keymap("n", "<D-S-e>", ":NvimTreeFocus<cr>", { silent = true, noremap = true })
