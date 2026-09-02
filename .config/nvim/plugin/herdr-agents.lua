if vim.env.HERDR_ENV ~= "1" then
    return
end

-- Prototype: browse and attach to herdr-managed coding agents from inside
-- nvim, so nvim (not herdr's own TUI) is the surface for working with them.
-- Herdr keeps running headless in the background as the thing that owns and
-- tracks the agent processes; nvim's own splits are the only layout used.

local function list_agents()
    local result = vim.system({ "herdr", "agent", "list" }, { text = true }):wait()

    if result.code ~= 0 then
        vim.notify("herdr agent list failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)
    if not ok then
        vim.notify("herdr agent list: failed to parse JSON", vim.log.levels.ERROR)
        return nil
    end

    return decoded.result.agents
end

-- Mirrors herdr's own status colors: idle/done green, working orange,
-- blocked red. Linked to Diagnostic groups so it follows the colorscheme
-- instead of hardcoding hex values.
vim.api.nvim_set_hl(0, "HerdrAgentIdle", { link = "DiagnosticOk", default = true })
vim.api.nvim_set_hl(0, "HerdrAgentWorking", { link = "DiagnosticWarn", default = true })
vim.api.nvim_set_hl(0, "HerdrAgentBlocked", { link = "DiagnosticError", default = true })
vim.api.nvim_set_hl(0, "HerdrAgentDone", { link = "DiagnosticOk", default = true })
vim.api.nvim_set_hl(0, "HerdrAgentUnknown", { link = "Comment", default = true })

local STATUS_ICON = {
    idle = { "○", "HerdrAgentIdle" },
    working = { "●", "HerdrAgentWorking" },
    blocked = { "●", "HerdrAgentBlocked" },
    done = { "●", "HerdrAgentDone" },
    unknown = { "○", "HerdrAgentUnknown" },
}

local function attach(pane_id)
    vim.cmd.vnew()
    vim.cmd("terminal herdr agent attach " .. vim.fn.shellescape(pane_id))
    vim.b.herdr_agent_pane = pane_id
    vim.cmd.startinsert()
end

local function pick_agent()
    local agents = list_agents()
    if not agents then
        return
    end
    if vim.tbl_isempty(agents) then
        vim.notify("No live herdr agents", vim.log.levels.INFO)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local config = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entry_display = require("telescope.pickers.entry_display")

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 2 },
            { width = 10 },
            { width = 40 },
            { remaining = true },
        },
    })

    pickers.new({}, {
        prompt_title = "Herdr Agents",
        finder = finders.new_table({
            results = agents,
            entry_maker = function(agent)
                return {
                    value = agent,
                    ordinal = table.concat({
                        agent.agent,
                        agent.agent_status,
                        agent.terminal_title_stripped or "",
                        agent.cwd or "",
                    }, " "),
                    display = function(entry)
                        local a = entry.value
                        return displayer({
                            STATUS_ICON[a.agent_status] or STATUS_ICON.unknown,
                            a.agent,
                            a.terminal_title_stripped or "",
                            vim.fn.fnamemodify(a.cwd or "", ":~"),
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
                if selection then
                    attach(selection.value.pane_id)
                end
            end)
            return true
        end,
    }):find()
end

vim.keymap.set("n", "<leader>ha", pick_agent, { desc = "Herdr: attach to agent" })
