if vim.env.HERDR_NVIM_SERVER ~= "1" then
    return
end

-- This instance is the shared headless server every herdr pane attaches to
-- via `--remote-ui`. Ctrl-C would otherwise just be forwarded to the server
-- as a keystroke; map it to `:detach` so it drops the local UI connection
-- and leaves the server (and everyone else attached to it) running.
vim.keymap.set({ "n", "i", "v", "t" }, "<C-c>", "<Cmd>detach<CR>", { desc = "Detach from shared herdr Neovim server" })
