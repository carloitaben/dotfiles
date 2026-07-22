-- On-the-fly "annotate a selection, export for an AI agent, clear" workflow.
-- Annotations are code-review-style notes tied to a line range, kept in
-- memory + persisted to disk, and rendered as virtual lines beneath their
-- range -- every annotation in a buffer is shown at once.

local ns = vim.api.nvim_create_namespace("annotations")
local sign_group = "AnnotationSigns"
vim.fn.sign_define("AnnotationMark", { text = "▶", texthl = "DiagnosticHint" })

local annotations = {}

-- annotation.col/end_col are only present for charwise selections (a
-- linewise `V` selection has no meaningful column range). Shared by the
-- in-buffer indicator and the clipboard export so both stay in sync.
local function format_range(annotation, line_prefix)
    if annotation.col then
        if annotation.line == annotation.end_line then
            return string.format("%s%d:%d-%d", line_prefix, annotation.line, annotation.col, annotation.end_col)
        end
        return string.format(
            "%s%d:%d-%s%d:%d",
            line_prefix,
            annotation.line,
            annotation.col,
            line_prefix,
            annotation.end_line,
            annotation.end_col
        )
    end

    if annotation.line == annotation.end_line then
        return string.format("%s%d", line_prefix, annotation.line)
    end
    return string.format("%s%d-%d", line_prefix, annotation.line, annotation.end_line)
end

local function annotations_path()
    return vim.fn.getcwd() .. "/.annotations.json"
end

local function load_annotations()
    local path = annotations_path()
    if vim.fn.filereadable(path) ~= 1 then
        return
    end

    local ok_read, lines = pcall(vim.fn.readfile, path)
    if not ok_read then
        return
    end

    local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if ok_decode and type(decoded) == "table" then
        annotations = decoded
    end
end

local function save_annotations()
    vim.fn.writefile({ vim.json.encode(annotations) }, annotations_path())
end

local function render_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.fn.sign_unplace(sign_group, { buffer = bufnr })

    local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    for _, annotation in ipairs(annotations) do
        local valid_range = type(annotation.line) == "number"
            and type(annotation.end_line) == "number"
            and annotation.line >= 1
            and annotation.end_line >= annotation.line
            and annotation.end_line <= line_count

        if annotation.file == bufname and valid_range then
            vim.fn.sign_place(0, sign_group, "AnnotationMark", bufnr, { lnum = annotation.line, priority = 100 })

            local virt_lines = {}
            if annotation.line ~= annotation.end_line or annotation.col then
                table.insert(virt_lines, {
                    { "▎ " .. format_range(annotation, "L"), "DiagnosticHint" },
                })
            end
            for _, line in ipairs(vim.split(annotation.message, "\n", { plain = true })) do
                table.insert(virt_lines, { { "▎ " .. line, "Comment" } })
            end

            vim.api.nvim_buf_set_extmark(bufnr, ns, annotation.end_line - 1, 0, {
                virt_lines = virt_lines,
            })
        end
    end
end

local function render_current_buffer()
    render_buffer(vim.api.nvim_get_current_buf())
end

local function clear_all_rendering()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
            vim.fn.sign_unplace(sign_group, { buffer = bufnr })
        end
    end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    callback = function(args) render_buffer(args.buf) end,
})

load_annotations()
vim.schedule(render_current_buffer)

-- Minimal floating markdown scratch buffer for typing a note. <C-s> in
-- normal or insert mode, or :w, submits. <Esc> (normal mode) also submits
-- -- if editing an existing annotation, an empty save leaves it untouched
-- rather than deleting it (see the empty-message check in annotate_range).
-- Always leaves you back in Normal mode (never stuck in Insert from the
-- note editor). opts.restore_visual re-selects the original visual range
-- with `gv` on cancel only -- saving deselects, matching a normal
-- visual-mode command.
local function prompt_for_note(initial_message, on_submit, opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    if initial_message then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(initial_message, "\n", { plain = true }))
    end

    local width = math.floor(vim.o.columns * 0.6)
    local height = math.floor(vim.o.lines * 0.4)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "single",
        title = initial_message
            and " Edit annotation (<C-s>/<Esc> save, <C-c> discard) "
            or " Annotation (<C-s>/<Esc> save, <C-c> discard) ",
        title_pos = "center",
    })

    if initial_message then
        vim.cmd("normal! G")
        vim.cmd("startinsert!")
    else
        vim.cmd("startinsert")
    end

    local handled = false

    local function submit()
        handled = true
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        vim.cmd("stopinsert")
        on_submit(table.concat(lines, "\n"))
    end

    local function cancel()
        handled = true
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        vim.cmd("stopinsert")
        local restore = opts.restore_visual
        if restore then
            -- Reconstruct the selection from what we captured when it was
            -- made, rather than trusting '</'> to still be intact after the
            -- floating window round trip. Deferred a tick: :stopinsert has
            -- its own deferred cursor-shift-left effect (like :startinsert,
            -- it doesn't fully resolve until Neovim is back waiting on real
            -- input) that otherwise lands after this and nudges the
            -- selection's end column back by one.
            vim.schedule(function()
                vim.fn.setpos(".", { 0, restore.start_line, restore.start_col, 0 })
                vim.cmd("normal! " .. restore.visual_type)
                vim.fn.setpos(".", { 0, restore.end_line, restore.end_col, 0 })
            end)
        end
    end

    vim.keymap.set({ "n", "i" }, "<C-s>", submit, { buffer = buf, desc = "Save annotation note" })
    vim.keymap.set("n", "<Esc>", submit, { buffer = buf, desc = "Save annotation note" })
    vim.keymap.set({ "n", "i" }, "<C-c>", cancel, { buffer = buf, desc = "Discard annotation note" })
    vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = submit })
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        callback = function()
            if not handled then
                cancel()
            end
        end,
    })
end

local function find_annotation(file, start_line, end_line)
    for index, annotation in ipairs(annotations) do
        if annotation.file == file and annotation.line == start_line and annotation.end_line == end_line then
            return index
        end
    end
    return nil
end

local function annotate_range(start_line, end_line, opts)
    opts = opts or {}
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")

    if file == "" then
        vim.notify("Annotations: current buffer has no file", vim.log.levels.ERROR)
        return
    end

    local existing_index = find_annotation(file, start_line, end_line)
    local initial_message = existing_index and annotations[existing_index].message or nil

    prompt_for_note(initial_message, function(message)
        if vim.trim(message) == "" then
            vim.notify("Annotations: empty note, annotation discarded", vim.log.levels.WARN)
            return
        end

        local entry = {
            file = file,
            line = start_line,
            end_line = end_line,
            col = opts.col,
            end_col = opts.end_col,
            message = message,
        }
        if existing_index then
            annotations[existing_index] = entry
        else
            table.insert(annotations, entry)
        end

        save_annotations()
        render_current_buffer()
    end, { restore_visual = opts.restore_visual })
end

local function annotate_visual_selection()
    local start_line, end_line, start_col, end_col, visual_type

    local mode = vim.fn.mode(1)
    if mode:match("^[vV\22]") then
        -- mini.clue's <leader> trigger replays "<leader>na" via an async
        -- nvim_feedkeys, so our callback can run while Visual mode is still
        -- technically active (mode() == "v") -- '</'> only get finalized once
        -- Visual mode actually ends, so they're stale/zero here. Read the
        -- live anchor + cursor instead, then exit Visual mode ourselves.
        visual_type = mode:sub(1, 1)
        start_line = vim.fn.line("v")
        end_line = vim.fn.line(".")
        start_col = vim.fn.col("v")
        end_col = vim.fn.col(".")

        if start_line > end_line or (start_line == end_line and start_col > end_col) then
            start_line, end_line = end_line, start_line
            start_col, end_col = end_col, start_col
        end

        vim.cmd("normal! \27")
    else
        visual_type = vim.fn.visualmode()
        start_line = vim.fn.line("'<")
        end_line = vim.fn.line("'>")
        start_col = vim.fn.col("'<")
        end_col = vim.fn.col("'>")
    end

    local restore = {
        start_line = start_line,
        start_col = start_col,
        end_line = end_line,
        end_col = end_col,
        visual_type = visual_type,
    }

    -- A linewise (V) selection has no meaningful column range to store.
    local stored_col, stored_end_col = start_col, end_col
    if visual_type == "V" then
        stored_col, stored_end_col = nil, nil
    end

    annotate_range(start_line, end_line, { col = stored_col, end_col = stored_end_col, restore_visual = restore })
end

local function annotate_current_line()
    local line = vim.fn.line(".")
    annotate_range(line, line)
end

local function annotation_entry(annotation)
    local range = format_range(annotation, "")
    local indented_message = annotation.message:gsub("\n", "\n  ")

    return string.format("- `%s:%s`\n\n  %s", annotation.file, range, indented_message)
end

local function copy_annotations()
    if #annotations == 0 then
        vim.notify("Annotations: nothing to copy", vim.log.levels.WARN)
        return nil
    end

    local entries = {}
    for _, annotation in ipairs(annotations) do
        table.insert(entries, annotation_entry(annotation))
    end
    vim.fn.setreg("+", table.concat(entries, "\n\n"))
    return #annotations
end

local function clear_annotations()
    local count = #annotations
    annotations = {}
    os.remove(annotations_path())
    clear_all_rendering()
    return count
end

local function copy_annotations_and_notify()
    local count = copy_annotations()
    if count then
        vim.notify(
            string.format("Annotations: copied %d annotation%s", count, count == 1 and "" or "s"),
            vim.log.levels.INFO
        )
    end
end

local function clear_annotations_and_notify()
    if #annotations == 0 then
        vim.notify("Annotations: nothing to clear", vim.log.levels.WARN)
        return
    end
    local count = clear_annotations()
    vim.notify(
        string.format("Annotations: cleared %d annotation%s", count, count == 1 and "" or "s"),
        vim.log.levels.INFO
    )
end

local function copy_and_clear_annotations()
    local count = copy_annotations()
    if not count then
        return
    end
    clear_annotations()
    vim.notify(
        string.format("Annotations: copied %d annotation%s, cleared.", count, count == 1 and "" or "s"),
        vim.log.levels.INFO
    )
end

vim.keymap.set("v", "<leader>na", annotate_visual_selection, { desc = "Annotations: annotate selection" })
vim.keymap.set("n", "<leader>na", annotate_current_line, { desc = "Annotations: annotate current line" })
vim.keymap.set("n", "<leader>ny", copy_and_clear_annotations, { desc = "Annotations: copy to clipboard and clear" })
vim.keymap.set("n", "<leader>nY", copy_annotations_and_notify, { desc = "Annotations: copy to clipboard" })
vim.keymap.set("n", "<leader>nc", clear_annotations_and_notify, { desc = "Annotations: clear" })
