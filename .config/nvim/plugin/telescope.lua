vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-telescope/telescope.nvim" },
    { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
    { src = "https://github.com/debugloop/telescope-undo.nvim" },
})

local function build_telescope_fzf_native(path)
    local result = vim.system({ "make" }, { cwd = path, text = true }):wait()

    if result.code ~= 0 then
        error(("Failed to build telescope-fzf-native.nvim:\n%s%s"):format(result.stdout, result.stderr))
    end
end

vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(event)
        local data = event.data

        if data.spec.name ~= "telescope-fzf-native.nvim" then
            return
        end

        if data.kind ~= "install" and data.kind ~= "update" then
            return
        end

        build_telescope_fzf_native(data.path)
    end,
})

local telescope = require("telescope")
local actions = require("telescope.actions")
local themes = require("telescope.themes")

telescope.setup({
    defaults = {
        -- preview = {
        --     treesitter = {
        --         disable = { "typescriptreact" },
        --     },
        -- },
        mappings = {
            i = {
                ["<esc>"] = actions.close
            },
        },
    },
    extensions = {
        fzf = {
            override_file_sorter = true,
            override_generic_sorter = true,
        },
        undo = {
            saved_only = true,
        }
    },
})

telescope.load_extension("fzf")
telescope.load_extension("undo")

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<D-p>', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find help' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Find keymaps' })
vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = 'Find Select Telescope' })
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = 'Find current word' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Find by grep' })
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Find diagnostics' })
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = 'Find resume' })
vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = 'Find recent files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })

vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(themes.get_dropdown {
        winblend = 10,
        previewer = false,
    })
end, { desc = 'Fuzzily find in current buffer' })

vim.keymap.set('n', '<leader>f/', function()
    builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
    }
end, { desc = 'Find by grep in open files' })

vim.keymap.set('n', '<leader>fu', telescope.extensions.undo.undo, { desc = 'Find undo history' })
