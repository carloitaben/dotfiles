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
-- floating scratch overlay that auto-dismisses on CursorMoved, so it can
-- never be navigated into or selected. Neovim's virt_lines are display-only
-- for the same reason: the cursor can't enter them. The only way to get
-- real navigation/selection is to insert the removed lines as real buffer
-- text; Zed's `do` does exactly that, and collapses them again on a second
-- `do` (or Esc, see plugin/mini.lua). Roll that ourselves on top of
-- gitsigns.get_hunks(). Shared state lives in lua/gitsigns_rescue.lua so
-- the global Esc mapping can collapse it too.
--
-- This is a workaround, not the real thing: these rescued lines are real
-- buffer text (BufWritePre strips them before any save, but they're there
-- in between). The proper fix is virt_lines + conceal_lines on one extmark,
-- toggling concealment instead of actually inserting/removing text -- see
-- neovim/neovim#32744 and #33033, both still open as of this writing.
local rescue = require('gitsigns_rescue')
local ns_rescue = rescue.ns
local ns_wash = rescue.ns_wash
local rescue_state = rescue.state
local collapse_rescue = rescue.collapse

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
  if not hunk then return end

  local removed_lines = {}
  for _, line in ipairs(hunk.lines) do
    if line:sub(1, 1) == '-' then
      table.insert(removed_lines, line:sub(2))
    end
  end

  local insert_row = math.max(hunk.added.start - 1, 0)
  if #removed_lines > 0 then
    vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, removed_lines)
  end

  local start_mark = vim.api.nvim_buf_set_extmark(bufnr, ns_rescue, insert_row, 0, { right_gravity = false })
  local end_mark = vim.api.nvim_buf_set_extmark(
    bufnr, ns_rescue, insert_row + #removed_lines, 0, { right_gravity = true }
  )
  rescue_state[bufnr] = { start_mark = start_mark, end_mark = end_mark }

  for i = 0, #removed_lines - 1 do
    vim.api.nvim_buf_set_extmark(bufnr, ns_rescue, insert_row + i, 0, {
      end_row = insert_row + i + 1,
      hl_group = 'DiffDelete',
      hl_eol = true,
      priority = 1000,
    })
  end

  -- Wash the hunk's current (added) side too, shifted down by whatever
  -- removed lines we just inserted above it: lines paired with a removed
  -- counterpart read as DiffChange, any tail-only additions as DiffAdd.
  -- This is what makes a pure addition (nothing removed) get highlighted
  -- treatment from `do` as well, and what makes a mixed hunk like
  -- change/add/add/change read as one continuous region instead of
  -- separately-colored lines.
  local added_start = insert_row + #removed_lines
  local change_count = math.min(hunk.added.count, hunk.removed.count)
  for i = 0, hunk.added.count - 1 do
    local hl = i < change_count and 'DiffChange' or 'DiffAdd'
    vim.api.nvim_buf_set_extmark(bufnr, ns_wash, added_start + i, 0, {
      end_row = added_start + i + 1,
      hl_group = hl,
      hl_eol = true,
      priority = 1000,
    })
  end
end, { desc = 'Toggle diff hunk (rescuable)' })

-- While a hunk is expanded, the rescued lines make the buffer temporarily
-- match the git ref again at that spot, so gitsigns' live diff no longer
-- sees the hunk gitsigns.nvim thinks is there ("no hunk to undo" and
-- friends). Collapse first so these always act on the real, current diff.
---@generic F: function
---@param fn F
---@return F
local function collapsing(fn)
  return function(...)
    collapse_rescue(vim.api.nvim_get_current_buf())
    return fn(...)
  end
end

vim.keymap.set('n', 'dp', collapsing(gitsigns.reset_hunk), { desc = 'Restore hunk' })

-- Never let an expanded (rescuable) hunk get written to disk.
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args) collapse_rescue(args.buf) end,
})

vim.keymap.set('n', '<leader>hs', collapsing(gitsigns.stage_hunk), { desc = 'Stage hunk' })
vim.keymap.set('n', '<leader>hr', collapsing(gitsigns.reset_hunk), { desc = 'Reset hunk' })
vim.keymap.set('n', '<leader>hS', collapsing(gitsigns.stage_buffer), { desc = 'Stage buffer' })
vim.keymap.set('n', '<leader>hR', collapsing(gitsigns.reset_buffer), { desc = 'Reset buffer' })
vim.keymap.set('n', '<leader>hu', collapsing(gitsigns.undo_stage_hunk), { desc = 'Undo stage hunk' })
vim.keymap.set('n', '<leader>hp', collapsing(gitsigns.preview_hunk), { desc = 'Preview hunk' })
vim.keymap.set('n', '<leader>hb', gitsigns.blame_line, { desc = 'Blame line' })
vim.keymap.set('n', '<leader>hd', collapsing(gitsigns.diffthis), { desc = 'Diff against index' })
