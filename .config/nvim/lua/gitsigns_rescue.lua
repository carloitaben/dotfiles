-- Shared state for the "rescue" hunk expansion in plugin/gitsigns.lua.
-- Pulled into its own module so plugin/mini.lua's global <Esc> mapping can
-- collapse it too, without gitsigns.lua and mini.lua racing over the keymap.

local M = {}

-- Removed lines get inserted as real (save-safe) buffer text in here; marks
-- track where to cut them back out again.
local ns = vim.api.nvim_create_namespace('gitsigns_rescue_inline')
-- Background wash over the hunk's current (added/changed) lines. Highlight
-- only, never edits the buffer, so it's just cleared rather than undone.
local ns_wash = vim.api.nvim_create_namespace('gitsigns_rescue_wash')

local state = {} ---@type table<integer, {start_mark: integer, end_mark: integer}>

M.ns = ns
M.ns_wash = ns_wash
M.state = state

---@param bufnr integer
---@return boolean collapsed
function M.collapse(bufnr)
  local st = state[bufnr]
  if not st then return false end
  state[bufnr] = nil
  vim.api.nvim_buf_clear_namespace(bufnr, ns_wash, 0, -1)
  local start_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, st.start_mark, {})
  local end_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, st.end_mark, {})
  vim.api.nvim_buf_del_extmark(bufnr, ns, st.start_mark)
  vim.api.nvim_buf_del_extmark(bufnr, ns, st.end_mark)
  if start_mark[1] and end_mark[1] then
    vim.api.nvim_buf_set_lines(bufnr, start_mark[1], end_mark[1], false, {})
  end
  return true
end

---@param bufnr integer
function M.collapse_current(bufnr)
  return M.collapse(bufnr or vim.api.nvim_get_current_buf())
end

return M
