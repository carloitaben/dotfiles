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
        ["."] = { "actions.cd", mode = "n" },
        ["h"] = { "actions.parent", mode = "n" },
        ["l"] = { "actions.select", mode = "n" },
        ["<tab>"] = { "actions.select", mode = "n" },
    },
    view_options = {
        show_hidden = true,
        is_always_hidden = function(name, _)
            return name == '..' or name == '.git'
        end,
    },
    ssh = {
        border = "single",
    },
    keymaps_help = {
        border = "single",
    },
})

vim.api.nvim_set_keymap("n", "<D-S-e>", ":Oil --preview<cr>", { silent = true, noremap = true })

