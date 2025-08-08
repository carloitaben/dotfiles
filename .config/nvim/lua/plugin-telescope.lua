
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-github.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
})


local telescope = require("telescope")

telescope.load_extension("gh")

vim.keymap.set("n", "<leader>ghi", function()
  telescope.extensions.gh.issues()
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>ghp", function()
  telescope.extensions.gh.pull_request()
end, { noremap = true, silent = true })

