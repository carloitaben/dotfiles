vim.pack.add({
    { src = "https://github.com/kitlangton/navi.nvim" },
})

vim.api.nvim_create_user_command("NaviLoad", function(opts)
    require("navi").load_file(opts.args)
end, { nargs = 1, complete = "file" })

-- vim.keymap.set("n", "<Tab>", "<Cmd>NaviNext<CR>", { desc = "Navi: Next stop" })
-- vim.keymap.set("n", "<S-Tab>", "<Cmd>NaviPrev<CR>", { desc = "Navi: Previous stop" })
-- vim.keymap.set("n", "<leader>np", "<Cmd>NaviPick<CR>", { desc = "Navi: Pick stop" })
-- vim.keymap.set("n", "<leader>nc", "<Cmd>NaviClear<CR>", { desc = "Navi: Clear tour" })
