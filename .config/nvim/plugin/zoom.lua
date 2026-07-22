-- Zoom the current window to fill its own tab, Zed-style (Shift+Esc). This
-- is Vim's native `:tab split` / `:tabclose` trick: zooming duplicates the
-- current window into a new tab (the original tab and its splits are left
-- untouched in the background, nothing running in them is reset), and
-- un-zooming just closes that tab to drop you back where you were.

local function toggle_zoom()
    if vim.t.zoomed then
        vim.cmd("tabclose")
    else
        vim.cmd("tab split")
        vim.t.zoomed = true
    end

    if vim.bo.buftype == "terminal" then
        vim.cmd("startinsert")
    end
end

vim.keymap.set({ "n", "t" }, "<S-Esc>", toggle_zoom, { desc = "Toggle zoom (fullscreen split as its own tab)" })
