local function diagnostic_counts()
    local counts = vim.diagnostic.count(0)
    local errors = counts[vim.diagnostic.severity.ERROR] or 0
    local warnings = counts[vim.diagnostic.severity.WARN] or 0

    if errors == 0 and warnings == 0 then
        return ''
    end

    return ('%sE:%d %sW:%d'):format(
        errors > 0 and '%#DiagnosticError#' or '',
        errors,
        warnings > 0 and '%#DiagnosticWarn#' or '',
        warnings
    ) .. '%#StatusLine#'
end

_G.dotfiles_diagnostic_counts = diagnostic_counts

vim.o.statusline = table.concat({
    ' %f',
    '%m',
    '%=',
    '%{%v:lua.dotfiles_diagnostic_counts()%}',
    '  %l:%c ',
})

vim.api.nvim_create_autocmd('DiagnosticChanged', {
    callback = function()
        vim.cmd('redrawstatus')
    end,
})
