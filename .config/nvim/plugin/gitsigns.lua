vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

local gitsigns = require("gitsigns")
gitsigns.setup({
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '−' },
    topdelete    = { text = '−' },
    changedelete = { text = '*' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = false,
  current_line_blame = true,
  current_line_blame_opts = {
    delay = 0,
    virt_text_pos = 'right_align',
  },
})

-- Jump to next git change
vim.keymap.set("n", "]c",
  function()
    if vim.wo.diff then
      vim.cmd.normal { ']c', bang = true }
    else
      gitsigns.nav_hunk 'next'
    end
  end,
  { desc = "Jump to next git change" }
)

-- Jump to previous git change
vim.keymap.set("n", "[c",
  function()
    if vim.wo.diff then
      vim.cmd.normal { '[c', bang = true }
    else
      gitsigns.nav_hunk 'prev'
    end
  end,
  { desc = "Jump to previous git change" }
)

-- Toggle stage hunk
vim.keymap.set("v", "<leader>hs", function()
  gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
end, { desc = "Toggle stage hunk" })

-- Add hunks as text object
vim.keymap.set({ 'o', 'x' }, 'ih', '<Cmd>Gitsigns select_hunk<CR>')

-- Keybinds from Zed
--
-- gitsigns.preview_hunk_inline() shows removed lines as virt_lines in a
-- floating scratch buffer, so the cursor can never land on them. Zed's
-- `do` inserts removed lines as real buffer text so they can be visually
-- selected (e.g. to "rescue" part of a hunk) and collapses them again on
-- a second `do`. Roll that ourselves on top of gitsigns.get_hunks().
local ns_rescue = vim.api.nvim_create_namespace('gitsigns_rescue_inline')
local rescue_state = {} ---@type table<integer, {start_mark: integer, end_mark: integer}>

---@param bufnr integer
---@return boolean collapsed
local function collapse_rescue(bufnr)
  local st = rescue_state[bufnr]
  if not st then return false end
  rescue_state[bufnr] = nil
  local start_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_rescue, st.start_mark, {})
  local end_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_rescue, st.end_mark, {})
  vim.api.nvim_buf_del_extmark(bufnr, ns_rescue, st.start_mark)
  vim.api.nvim_buf_del_extmark(bufnr, ns_rescue, st.end_mark)
  if start_mark[1] and end_mark[1] then
    vim.api.nvim_buf_set_lines(bufnr, start_mark[1], end_mark[1], false, {})
  end
  return true
end

---@param bufnr integer
---@param lnum integer 1-based
---@return table? hunk
local function get_cursor_hunk(bufnr, lnum)
  for _, hunk in ipairs(gitsigns.get_hunks(bufnr) or {}) do
    local a = hunk.added
    local lo = math.max(a.start, 1)
    local hi = math.max(a.start + math.max(a.count - 1, 0), 1)
    if lnum >= lo and lnum <= hi then
      return hunk
    end
  end
end

vim.keymap.set('n', 'do', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.fn.line('.')

  if rescue_state[bufnr] then
    local st = rescue_state[bufnr]
    local start_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_rescue, st.start_mark, {})
    local end_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_rescue, st.end_mark, {})
    local inside = start_mark[1] and end_mark[1]
      and (lnum - 1) >= start_mark[1] and (lnum - 1) <= end_mark[1]
    collapse_rescue(bufnr)
    if inside then return end
  end

  local hunk = get_cursor_hunk(bufnr, lnum)
  if not hunk or hunk.removed.count == 0 then
    -- Pure addition (or no hunk here): nothing to rescue, fall back to
    -- gitsigns' own inline preview for the word-diff highlighting.
    gitsigns.preview_hunk_inline()
    return
  end

  local removed_lines = {}
  for _, line in ipairs(hunk.lines) do
    if line:sub(1, 1) == '-' then
      table.insert(removed_lines, line:sub(2))
    end
  end

  local insert_row = math.max(hunk.added.start - 1, 0)
  vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, removed_lines)

  local start_mark = vim.api.nvim_buf_set_extmark(bufnr, ns_rescue, insert_row, 0, { right_gravity = false })
  local end_mark = vim.api.nvim_buf_set_extmark(
    bufnr, ns_rescue, insert_row + #removed_lines, 0, { right_gravity = true }
  )
  rescue_state[bufnr] = { start_mark = start_mark, end_mark = end_mark }

  for i = 0, #removed_lines - 1 do
    vim.api.nvim_buf_set_extmark(bufnr, ns_rescue, insert_row + i, 0, {
      end_row = insert_row + i + 1,
      hl_group = 'GitSignsDeleteVirtLn',
      hl_eol = true,
      priority = 1000,
    })
  end
end, { desc = 'Toggle diff hunk (rescuable)' })

vim.keymap.set('n', 'dp', gitsigns.reset_hunk, { desc = 'Restore hunk' })

-- Never let an expanded (rescuable) hunk get written to disk.
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args) collapse_rescue(args.buf) end,
})

vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset hunk' })
vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage buffer' })
vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset buffer' })
vim.keymap.set('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Undo stage hunk' })
vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview hunk' })
vim.keymap.set('n', '<leader>hb', gitsigns.blame_line, { desc = 'Blame line' })
vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff against index' })
