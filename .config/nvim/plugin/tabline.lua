-- The default tabline abbreviates the path to disambiguate same-named
-- buffers across tabs (e.g. "~/D/p/a/a/l/m/changeImageFormat.ts"). Show just
-- the filename instead.
local function tab_label(tabnr)
    local windows = vim.fn.tabpagebuflist(tabnr)
    local bufnr = windows[vim.fn.tabpagewinnr(tabnr)]
    local name = vim.fn.bufname(bufnr)
    local label = name == '' and '[No Name]' or vim.fn.fnamemodify(name, ':t')

    if vim.fn.getbufvar(bufnr, '&modified') == 1 then
        label = label .. ' +'
    end

    return label
end

function _G.dotfiles_tabline()
    local parts = {}

    for tabnr = 1, vim.fn.tabpagenr('$') do
        local highlight = tabnr == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#'
        table.insert(parts, ('%s%%%dT %s '):format(highlight, tabnr, tab_label(tabnr)))
    end

    table.insert(parts, '%#TabLineFill#%T')

    return table.concat(parts)
end

vim.o.tabline = '%!v:lua.dotfiles_tabline()'
