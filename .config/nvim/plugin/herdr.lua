if vim.env.HERDR_ENV ~= "1" or not vim.env.HERDR_WORKSPACE_ID then
    return
end

-- One warm nvim per herdr workspace: expose a socket so lazygit's `o`
-- (bin/nvim-herdr-open) can hand files to this instance instead of cold-starting.
-- Socket path must match bin/nvim-herdr-open.
local runtime_dir = (vim.env.XDG_RUNTIME_DIR or vim.env.TMPDIR or "/tmp"):gsub("/$", "")
local socket = ("%s/nvim-herdr-%d-%s.sock"):format(runtime_dir, vim.uv.getuid(), vim.env.HERDR_WORKSPACE_ID)

if vim.uv.fs_stat(socket) then
    local ok, channel = pcall(vim.fn.sockconnect, "pipe", socket)
    if ok then
        -- Another nvim already owns this workspace's socket.
        vim.fn.chanclose(channel)
        return
    end
    os.remove(socket)
end

vim.fn.serverstart(socket)
