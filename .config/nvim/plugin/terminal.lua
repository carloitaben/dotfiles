-- Mirrors Zed's Cmd+J: toggles a terminal as a vertical split docked at the
-- far right of the current tab. Hiding it just closes the window(s) -- the
-- underlying job (e.g. a dev server) keeps running in the background --
-- and showing it again reuses the same buffer instead of starting a new
-- shell.
--
-- Interacts with zoom.lua's <S-Esc>: zooming duplicates the terminal's
-- window into its own fullscreen tab while the original split stays alive
-- in the background, so a naive "close the one window I remember" toggle
-- breaks (the tracked handle goes stale, and re-showing opens a stray
-- extra split next to the still-live zoomed one). Instead we look up every
-- window currently showing the terminal buffer, in any tab, and hide them
-- all -- remembering whether one of them was zoomed so showing it again
-- restores the same fullscreen state instead of dropping back to a plain
-- split.

local term_buf = nil
local was_zoomed = false
local term_width = 0.4

local function terminal_windows()
    if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
        return {}
    end
    return vim.fn.win_findbuf(term_buf)
end

local function hide_terminal(wins)
    was_zoomed = false
    for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
            local tab = vim.api.nvim_win_get_tabpage(win)
            if vim.t[tab].zoomed then
                was_zoomed = true
            end
            vim.api.nvim_win_close(win, false)
        end
    end
end

local function show_terminal()
    vim.cmd("botright vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * term_width))

    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_win_set_buf(win, term_buf)
    else
        vim.cmd("terminal")
        term_buf = vim.api.nvim_get_current_buf()
    end

    if was_zoomed then
        vim.cmd("tab split")
        vim.t.zoomed = true
    end

    vim.cmd("startinsert")
end

local function toggle_terminal_split()
    local wins = terminal_windows()
    if #wins > 0 then
        hide_terminal(wins)
    else
        show_terminal()
    end
end

vim.keymap.set({ "n", "t" }, "<D-j>", toggle_terminal_split, { desc = "Toggle terminal (right split)" })

-- <C-w> is swallowed by the shell in terminal mode otherwise (zsh treats it
-- as delete-word-backward), so window commands like <C-w>v/<C-w>w never
-- reach Neovim. Leave terminal mode first, then replay <C-w> for real.
vim.keymap.set("t", "<C-w>", "<C-\\><C-n><C-w>", { desc = "Window commands from terminal mode" })
