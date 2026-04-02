vim.pack.add({ 'https://github.com/dmtrKovalenko/fff.nvim' })

vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(event)
        if event.data.updated then
            require('fff.download').download_or_build_binary()
        end
    end,
})

-- the plugin will automatically lazy load
vim.g.fff = {
    lazy_sync = true, -- start syncing only when the picker is open
    debug = {
        enabled = true,
        show_scores = true,
    },
}

vim.keymap.set(
    'n',
    'ff',
    function() require('fff').find_files() end,
    { desc = 'FFFind files' }
)
