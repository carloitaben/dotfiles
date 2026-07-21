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
local action_state = require("telescope.actions.state")
local config = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
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

-- Force the preview parse to happen synchronously
local sync_highlight = require("ts_sync_highlight").sync_highlight
local previewer_utils = require("telescope.previewers.utils")
local original_ts_highlighter = previewer_utils.ts_highlighter
previewer_utils.ts_highlighter = function(bufnr, ft)
    local attached = original_ts_highlighter(bufnr, ft)
    if attached ~= false then
        sync_highlight(bufnr)
    end
    return attached
end

local builtin = require('telescope.builtin')

local function open_project_in_new_terminal(root)
    local terminal = vim.env.TERMINAL

    if terminal == nil or terminal == '' then
        vim.notify('TERMINAL is not set', vim.log.levels.ERROR, { title = 'Open Recent Project' })
        return
    end

    vim.fn.jobstart({
        'open',
        '-na',
        terminal,
        '--args',
        '-e',
        '/bin/zsh',
        '-lc',
        ('cd %s && exec nvim'):format(vim.fn.shellescape(root)),
    }, { detach = true })
end

local function replace_current_session(root)
    -- Refuse to switch projects if any normal buffer still has unsaved changes.
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].modified then
            vim.notify('Save or discard changes first', vim.log.levels.WARN, { title = 'Open Recent Project' })
            return
        end
    end

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buffer) then
            local buftype = vim.bo[buffer].buftype

            if buftype == '' then
                vim.api.nvim_buf_delete(buffer, { force = false })
            end
        end
    end

    -- Start the selected project with a fresh unnamed buffer in the new cwd.
    vim.cmd.cd(root)
    vim.cmd.enew()
end

local function select_recent_project(prompt_bufnr, action)
    local selection = action_state.get_selected_entry()

    actions.close(prompt_bufnr)

    if selection == nil then
        return
    end

    action(selection[1])
end

local function open_recent_project()
    local roots = {}
    local seen = {}

    -- Build a recent-project list from oldfiles, collapsing many files per repo
    -- down to a single git root while preserving recency.
    for _, file in ipairs(vim.v.oldfiles) do
        local root = vim.fs.root(file, { ".git" })

        if root ~= nil and not seen[root] then
            seen[root] = true
            table.insert(roots, root)
        end
    end

    pickers.new(themes.get_dropdown({
        previewer = false,
        prompt_title = 'Open Recent Project',
        layout_config = {
            width = 100,
        },
    }), {
        finder = finders.new_table({
            results = roots,
        }),
        sorter = config.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                select_recent_project(prompt_bufnr, replace_current_session)
            end)

            -- Cmd+Enter keeps the current Neovim untouched and opens the repo in a
            -- separate terminal window instead.
            local function open_in_new_window()
                select_recent_project(prompt_bufnr, open_project_in_new_terminal)
            end

            map({ 'i', 'n' }, '<D-CR>', open_in_new_window)
            map({ 'i', 'n' }, '<D-Enter>', open_in_new_window)

            return true
        end,
    }):find()
end

-- Native Ex commands (:write, :split, ...) aren't in nvim_get_commands(), only
-- user/plugin-defined ones are. Their one-line descriptions live in the help
-- index instead, so scrape that for a name -> description map, keeping only
-- entries that resolve to a real, fully-named command.
local builtin_commands_cache

local function get_builtin_commands()
    if builtin_commands_cache then
        return builtin_commands_cache
    end

    builtin_commands_cache = {}

    local runtime = vim.env.VIMRUNTIME
    local ok, lines = pcall(vim.fn.readfile, runtime and (runtime .. '/doc/index.txt') or '')

    if not ok then
        return builtin_commands_cache
    end

    local current
    for _, line in ipairs(lines) do
        local name, desc = line:match('^|:([%w_]+)|%s+:%S+%s+(.*)$')
        if name then
            desc = vim.trim(desc)
            desc = desc:sub(1, 1):upper() .. desc:sub(2)
            current = vim.fn.exists(':' .. name) == 2 and { name = name, desc = desc } or nil
            if current then
                table.insert(builtin_commands_cache, current)
            end
        elseif current and line:match('^%s+%S') then
            current.desc = current.desc .. ' ' .. vim.trim(line)
        else
            current = nil
        end
    end

    return builtin_commands_cache
end

-- A command's `definition` doubles as its description: set to the `desc`
-- given at creation, if any, otherwise the raw script/Lua body that runs.
-- There is no way to tell those two cases apart from the API, so fall back to
-- pattern-matching what code tends to look like and blank it out.
local function describe_user_command(definition)
    if
        definition == ''
        or definition:match('^:')
        or definition:match('^call ')
        or definition:match('^lua ')
        or definition:match('^silent')
        or definition:match('<f%-args>')
        or definition:match('<q%-args>')
        or definition:match('<args>')
        or definition:match('<bang>')
        or definition:match("require[('\"]")
    then
        return ''
    end
    return definition
end

local function collect_commands()
    local by_name = {}

    for _, cmd in ipairs(get_builtin_commands()) do
        by_name[cmd.name] = cmd
    end

    for _, cmd in pairs(vim.api.nvim_get_commands({})) do
        by_name[cmd.name] = { name = cmd.name, desc = describe_user_command(cmd.definition) }
    end

    local buf_commands = vim.api.nvim_buf_get_commands(0, {})
    buf_commands[true] = nil
    for _, cmd in pairs(buf_commands) do
        by_name[cmd.name] = { name = cmd.name, desc = describe_user_command(cmd.definition) }
    end

    local results = {}
    for _, cmd in pairs(by_name) do
        table.insert(results, cmd)
    end
    table.sort(results, function(a, b) return a.name < b.name end)

    return results
end

local command_palette_displayer = entry_display.create({
    separator = ' ',
    items = {
        { width = 30 },
        { remaining = true },
    },
})

local function command_palette()
    pickers.new(themes.get_dropdown({
        previewer = false,
        prompt_title = 'Command Palette',
        layout_config = {
            width = 100,
        },
    }), {
        finder = finders.new_table({
            results = collect_commands(),
            entry_maker = function(cmd)
                return {
                    name = cmd.name,
                    desc = cmd.desc,
                    value = cmd,
                    ordinal = cmd.name .. ' ' .. cmd.desc,
                    display = function(entry)
                        return command_palette_displayer({
                            { entry.name, 'TelescopeResultsIdentifier' },
                            entry.desc,
                        })
                    end,
                }
            end,
        }),
        sorter = config.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()

                actions.close(prompt_bufnr)

                if selection == nil then
                    return
                end

                -- Run it outright, like a VSCode/Zed palette would. Nvim
                -- validates required arguments before a command's body runs,
                -- so a missing-argument error surfaces here safely; fall back
                -- to dropping it on the command line for the user to finish.
                vim.cmd('stopinsert')
                if not pcall(vim.cmd, selection.name) then
                    vim.api.nvim_feedkeys((':%s '):format(selection.name), 'nt', false)
                end
            end)

            return true
        end,
    }):find()
end

vim.keymap.set('n', '<D-p>', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<D-S-p>', command_palette, { desc = 'Command palette' })
vim.keymap.set('n', '<D-M-o>', open_recent_project, { desc = 'Open recent project' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find help' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Find keymaps' })
vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = 'Find Select Telescope' })
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = 'Find current word' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Find by grep' })
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Find diagnostics' })
vim.keymap.set('n', '<leader>fo', open_recent_project, { desc = 'Open recent project' })
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
