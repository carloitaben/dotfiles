vim.pack.add({
    { src = "https://github.com/stevearc/oil.nvim" },
})

local oil = require("oil")

oil.setup({
    default_file_explorer = true,
    columns = {
        "icon",
    },
    float = {
        preview_split = "right",
        win_options = {
            number = true,
            relativenumber = true,
            signcolumn = "no",
            cursorline = true,
        }
    },
    delete_to_trash = false,
    skip_confirm_for_simple_edits = true,
    keymaps = {
        ["<Esc>"] = { "actions.close", mode = "n" },
        ["<tab>"] = { "actions.select", mode = "n" },
        ["h"] = { "actions.parent", mode = "n" },
        ["l"] = { "actions.select", mode = "n" },
        ["yp"] = {
        desc = "Copy file path to clipboard",
        callback = function()
          require("oil.actions").copy_entry_path.callback()
          vim.fn.setreg("+", vim.fn.getreg(vim.v.register))
          vim.notify("Copied path", "info", { title = "Oil" })
        end,
      },
    },
    view_options = {
        show_hidden = true,
        is_always_hidden = function(name, _)
            return name == '..' or name == '.git'
        end,
    },
    float = {
                max_width = 0.9,
    max_height = 0.9,

        border = "single",
    },
    ssh = {
        border = "single",
    },
    keymaps_help = {
        border = "single",
    },
})

vim.api.nvim_set_keymap("n", "<D-S-e>", ":Oil --float --preview<cr>", { silent = true, noremap = true })

