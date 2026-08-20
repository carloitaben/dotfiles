local repl_script = vim.fn.expand('~/.config/herdr/bin/bun-repl')

local function send_to_bun_repl(lines)
    if #lines == 0 then
        return
    end

    vim.system({ repl_script, 'send' }, { stdin = table.concat(lines, '\n') }, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                vim.notify(vim.trim(result.stderr or 'Unable to send code to Bun REPL'), vim.log.levels.ERROR)
            end)
        end
    end)
end

local function send_current_line()
    send_to_bun_repl({ vim.api.nvim_get_current_line() })
end

local function send_visual_selection()
    local start_line = vim.fn.getpos("'<")[2]
    local end_line = vim.fn.getpos("'>")[2]
    send_to_bun_repl(vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false))
end

local function send_buffer()
    send_to_bun_repl(vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

vim.keymap.set('n', '<leader>rl', send_current_line, { desc = 'Send line to Bun REPL' })
vim.keymap.set('n', '<leader>rf', send_buffer, { desc = 'Send file to Bun REPL' })
vim.keymap.set('x', '<leader>rs', send_visual_selection, { desc = 'Send selection to Bun REPL' })
