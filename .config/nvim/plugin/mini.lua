vim.pack.add({
    { src = "https://github.com/echasnovski/mini.nvim" },
})

require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.surround").setup()
require("mini.completion").setup()
require("mini.statusline").setup({ use_icons = false })
require("mini.tabline").setup({ show_icons = false })

local MiniFiles = require("mini.files")

MiniFiles.setup({
    options = {
        permanent_delete = false,
    },
    mappings = {
        close = "<Esc>",
    },
    windows = {
        preview = true,
        width_preview = 40,
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
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
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

-- Clear search highlights when pressing Esc in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

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
