vim.pack.add({
    { src = "https://github.com/echasnovski/mini.nvim" },
})

-- netrw's directory listing is the "picker" that pops up when nvim opens on
-- a directory (`nvim .`, `nvim ~/proj`). Disable it in favor of mini.files
-- below, which we already use everywhere else.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.surround").setup()
require("mini.completion").setup()
-- Minimal statusline: mode, branch, filename, diagnostics, fileinfo,
-- location. Drops mini.statusline's default diff/LSP-attached indicators
-- (noisy, low-signal), "Git" text label, file size, and line/col totals.
-- Diagnostic counts are colored via the builtin Diagnostic* highlight
-- groups instead of carrying a letter/symbol prefix -- color alone conveys
-- severity, since the groups are always shown in the same error/warn/hint
-- order.
local MiniStatusline = require("mini.statusline")

local DIAGNOSTIC_SPECS = {
    { severity = vim.diagnostic.severity.ERROR, hl = "DiagnosticError" },
    { severity = vim.diagnostic.severity.WARN,  hl = "DiagnosticWarn" },
    { severity = vim.diagnostic.severity.HINT,  hl = "DiagnosticHint" },
}

local function diagnostic_groups()
    local groups = {}
    for _, spec in ipairs(DIAGNOSTIC_SPECS) do
        local n = #vim.diagnostic.get(0, { severity = spec.severity })
        if n > 0 then
            table.insert(groups, { hl = spec.hl, strings = { tostring(n) } })
        end
    end
    return groups
end

-- mini.statusline's own section_git prepends a "Git"/"" icon label; we just
-- want the branch name.
local function git_branch()
    local summary = vim.b.minigit_summary_string or vim.b.gitsigns_head
    if summary == nil then return "" end
    return summary == "" and "-" or summary
end

-- Same "encoding :: fileformat :: filetype" shape as fileinfo, minus the
-- file size mini.statusline's own section_fileinfo tacks on.
local function fileinfo_string()
    local filetype = vim.bo.filetype
    if filetype == "" then return "" end
    local encoding = vim.bo.fileencoding
    if encoding == "" then encoding = vim.o.encoding end
    return string.format("%s :: %s :: %s", encoding, vim.bo.fileformat, filetype)
end

MiniStatusline.setup({
    use_icons = false,
    content = {
        active = function()
            local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
            local filename = MiniStatusline.section_filename({ trunc_width = 140 })

            local groups = {
                { hl = mode_hl,                    strings = { mode } },
                { hl = "MiniStatuslineDevinfo",     strings = { git_branch() } },
            }
            vim.list_extend(groups, diagnostic_groups())
            vim.list_extend(groups, {
                "%<",
                { hl = "MiniStatuslineFilename", strings = { filename } },
                "%=",
                { hl = "MiniStatuslineFileinfo", strings = { fileinfo_string() } },
                { hl = mode_hl,                  strings = { "%l:%2v" } },
            })
            return MiniStatusline.combine_groups(groups)
        end,
    },
})
require("mini.tabline").setup({ show_icons = false })

local MiniFiles = require("mini.files")

MiniFiles.setup({
    options = {
        permanent_delete = false,
        -- Don't hijack `nvim <dir>` / `:e <dir>` (mini.files' default,
        -- replacing netrw) -- only open it via the explicit keymap below.
        use_as_default_explorer = false,
    },
    mappings = {
        close = "<Esc>",
    },
    windows = {
        preview = true,
        width_preview = 40,
    },
})

-- Mega minimal dashboard for bare `nvim` (no file/dir args): just actions,
-- no ASCII art or padding sections.
require("mini.starter").setup({
    header = "",
    footer = "",
    items = {
        { name = "Find file",    action = "Telescope find_files", section = "" },
        { name = "Recent files", action = "Telescope oldfiles",   section = "" },
        { name = "Explorer",     action = function() MiniFiles.open(vim.fn.getcwd(), false) end, section = "" },
        { name = "Quit",         action = "qa",                   section = "" },
    },
    content_hooks = {
        require("mini.starter").gen_hook.aligning("center", "center"),
    },
})

vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
        local buf_id = args.data.buf_id

        vim.keymap.set("n", "yp", function()
            local path = (MiniFiles.get_fs_entry() or {}).path
            if path == nil then return end
            vim.fn.setreg("+", path)
            vim.notify("Copied path", vim.log.levels.INFO, { title = "mini.files" })
        end, { buffer = buf_id, desc = "Copy file path to clipboard" })

        -- Default mappings only bind go_in/go_out to h/l/H/L; add the more
        -- conventional <CR>/<Space> as extra ways to open without losing h/l.
        -- <CR> closes the picker after opening a file (close_on_file); h/l/L
        -- and <Space> stay open so browsing multiple files is still cheap.
        vim.keymap.set("n", "<CR>", function()
            MiniFiles.go_in({ close_on_file = true })
        end, { buffer = buf_id, desc = "Open and close" })
        vim.keymap.set("n", "<Space>", MiniFiles.go_in, { buffer = buf_id, desc = "Open" })

        -- The explorer buffer isn't a real file, so the global <D-s> -> :w
        -- keymap errors ("cannot be saved"). Renames/creates/deletes staged
        -- in the buffer are applied via synchronize(), not :w.
        vim.keymap.set("n", "<D-s>", MiniFiles.synchronize,
            { buffer = buf_id, desc = "Apply changes" })
    end,
})

-- mini.files renders its preview into a disposable scratch buffer (readfile
-- + treesitter, thrown away on cursor move), so previewing a file does
-- nothing for the *real* buffer nvim creates when you actually open it --
-- that one still pays a fresh read + first-parse cost. Prewarm the real
-- buffer in the background as soon as it's previewed, same trick as the
-- telescope previewer override in telescope.lua: by the time `go_in` runs,
-- `vim.fn.bufadd` + `nvim_win_set_buf` (what mini.files' `H.edit` does) finds
-- an already-loaded, already-highlighted buffer instead of a cold one.
local sync_highlight = require("ts_sync_highlight").sync_highlight

-- Match mini.files' own cutoff for whether its scratch preview bothers
-- highlighting at all (`H.buffer_should_highlight`), so we never do a full
-- read+parse of a file mini.files itself would consider too big to preview.
local PREWARM_MAX_BYTES = 1000000

-- Throttled, not debounced: drilling straight down into a directory tree to
-- a known file lands on it once and gets opened right away, so that first
-- landing needs to warm immediately, not after a delay it'll beat anyway.
-- Only when the cursor keeps moving (browsing several files) do we throttle,
-- so a fast scroll through many entries only warms the one it settles on.
local prewarm_timer = vim.uv.new_timer()
local last_leading_path = nil

local function prewarm(path)
    local stat = vim.uv.fs_stat(path)
    if stat == nil or stat.size > PREWARM_MAX_BYTES then return end

    local buf_id = vim.fn.bufadd(path)
    -- Already loaded means either we prewarmed it before, or it's the real
    -- buffer from an actual open (which ran its own sync_highlight via the
    -- FileType autocmd in treesitter.lua). Either way its treesitter state
    -- is already whatever it is; re-driving sync_highlight's internal,
    -- non-reentrant parse stepper on it can race nvim's own async
    -- highlighter for that buffer and silently corrupt its parse state,
    -- leaving it stuck unhighlighted.
    if vim.api.nvim_buf_is_loaded(buf_id) then return end

    vim.fn.bufload(buf_id)
    sync_highlight(buf_id)
end

vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferUpdate",
    callback = function()
        local entry = MiniFiles.get_fs_entry()
        if entry == nil or entry.fs_type ~= "file" then return end
        local path = entry.path

        if not prewarm_timer:is_active() then
            last_leading_path = path
            prewarm(path)
        end

        prewarm_timer:stop()
        prewarm_timer:start(60, 0, vim.schedule_wrap(function()
            if path ~= last_leading_path then prewarm(path) end
        end))
    end,
})


-- `snippets.ts-shared` is one file shared by both `typescript` and
-- `typescriptreact` contexts, so snippets don't need to be duplicated per
-- filetype the way VS Code/Zed's static snippet files force.
-- `snippets.tsx-react` holds the React/Next.js-only snippets (`.tsx` alone).
require("mini.snippets").setup({
    snippets = {
        require("mini.snippets").gen_loader.from_lang(),
        function(ctx)
            if ctx.lang ~= "typescript" and ctx.lang ~= "typescriptreact" then return {} end
            return require("snippets.ts-shared")
        end,
        function(ctx)
            if ctx.lang ~= "typescriptreact" then return {} end
            return require("snippets.tsx-react")
        end,
    },
})

-- Tab accepts the selected completion item when the popup menu is open;
-- otherwise it's a normal Tab. `noinsert` in completeopt keeps an item
-- pre-selected, so <C-y> confirms it without having to arrow down first.
vim.keymap.set("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-y>"
    end
    return "<Tab>"
end, { expr = true, noremap = true, silent = true, desc = "Accept completion" })

-- Enter accepts the selected completion item without also inserting a
-- newline (same reasoning as Tab above: 'noinsert' means the highlighted
-- item was never actually written into the buffer, so plain <CR> doesn't
-- know to confirm it).
vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-y>"
    end
    return "<CR>"
end, { expr = true, noremap = true, silent = true, desc = "Accept completion" })
-- `gw` mirrors Zed's jump ([g]o [w]ord). Overrides the builtin `gw` (format
-- keeping cursor position), which isn't used here.
require("mini.jump2d").setup({
    mappings = { start_jumping = "gw" },
})

require("mini.move").setup({
    mappings = {
        -- Move visual selection in Visual mode
        left = '<',
        right = '>',
        down = 'J',
        up = 'K',
        -- Move current line in Normal mode
        line_left = '<M-h>',
        line_right = '<M-l>',
        line_down = '<M-j>',
        line_up = '<M-k>',
    },
})

-- Only trigger on <Leader>: this is a cheatsheet for our own custom
-- mappings, not a global popup for every built-in prefix key (g, z, marks,
-- registers, ...) -- those fired on nearly every normal edit and were the
-- "shows too much" noise.
local miniclue = require("mini.clue")

miniclue.setup({
    window = {
        config = {
            width = 'auto',
        },
        delay = 0,
    },
    triggers = {
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },
    },
    clues = {
        { mode = 'n', keys = '<Leader>n', desc = '+Annotations' },
        { mode = 'x', keys = '<Leader>n', desc = '+Annotations' },
    },
})

-- ⌘+s to write file
vim.keymap.set({ "n", "v", "i" }, "<D-s>", "<cmd>:w<CR>", { noremap = true, silent = true, desc = "Write file" })

-- ⌘+shift-s to write all files
vim.keymap.set({ "n", "v", "i" }, "<D-S-s>", "<cmd>:wa<CR>", { noremap = true, silent = true, desc = "Write all files" })

-- ⌘+, to open dotfiles
vim.keymap.set({ "n", "v", "i" }, "<D-,>", ":e ~/.dotfiles<CR>",
    { noremap = true, silent = true, desc = "Open dotfiles" })

-- ⌘+w to close the current tab (Zed's cmd+w); on the last tab falls back to
-- :bd so it never errors with "Cannot close last tab page".
vim.keymap.set("n", "<D-w>", function()
    if vim.fn.tabpagenr("$") > 1 then
        vim.cmd("tabclose")
    else
        vim.cmd("bd")
    end
end, { noremap = true, silent = true, desc = "Close tab" })

-- ⌘+a to select the whole file (Zed's cmd+a; vim-native ggVG)
vim.keymap.set("n", "<D-a>", "ggVG", { noremap = true, silent = true, desc = "Select all" })

-- ⌘+shift+e to open the file explorer (Zed/VS Code convention)
vim.keymap.set("n", "<D-S-e>", function()
    local name = vim.api.nvim_buf_get_name(0)
    MiniFiles.open(name ~= "" and name or vim.fn.getcwd(), false)
end, { silent = true, noremap = true, desc = "Open file explorer" })

-- Format, keeping cursor position (like the builtin `gw` operator does for
-- `gq`-style formatting).
vim.keymap.set("n", "<leader>f", function()
    local view = vim.fn.winsaveview()
    vim.lsp.buf.format()
    vim.fn.winrestview(view)
end, { noremap = true, silent = true, desc = "Format (keep cursor)" })
vim.keymap.set("x", "<leader>f", function()
    local view = vim.fn.winsaveview()
    vim.lsp.buf.format()
    vim.fn.winrestview(view)
end, { noremap = true, silent = true, desc = "Format selection (keep cursor)" })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Clear search highlights when pressing Esc in normal mode, and collapse an
-- expanded gitsigns "rescue" hunk (see plugin/gitsigns.lua) if one is open.
vim.keymap.set('n', '<Esc>', function()
    require('gitsigns_rescue').collapse_current()
    vim.cmd.nohlsearch()
end)

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Keep the cursor centered when jumping between search matches
vim.keymap.set("n", "n", "nzzzv", { noremap = true, silent = true })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true, silent = true })

-- Keep the cursor centered while scrolling half a page
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })

-- Keep the cursor centered when moving through jump history
vim.keymap.set("n", "<C-o>", "<C-o>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { noremap = true, silent = true })
