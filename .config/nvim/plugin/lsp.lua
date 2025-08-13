vim.pack.add({
        { src = "https://github.com/neovim/nvim-lspconfig" },
        { src = "https://github.com/mason-org/mason.nvim" },
        { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
})

vim.lsp.enable({ "lua_ls", "bashls" })

vim.lsp.config("lua_ls", {
        settings = {
                Lua = {
                        workspace = {
                                library = vim.api.nvim_get_runtime_file("", true)
                        }

                }
        }
})

require("mason").setup()
require("mason-lspconfig").setup()

vim.diagnostic.config({
        virtual_text = true,
})

-- vim.api.nvim_create_autocmd('LspAttach', {
-- desc = 'Set up completions',
-- callback = function(ev)
--   local client = vim.lsp.get_client_by_id(ev.data.client_id)
--   if client:supports_method('textDocument/completion') then
--     vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
--   end
-- end,
--)

local fmt_group = vim.api.nvim_create_augroup('autoformat_cmds', { clear = true })

local function setup_autoformat(event)
        local id = vim.tbl_get(event, 'data', 'client_id')
        local client = id and vim.lsp.get_client_by_id(id)
        if client == nil then
                return
        end

        vim.api.nvim_clear_autocmds({ group = fmt_group, buffer = event.buf })

        local buf_format = function(e)
                vim.lsp.buf.format({
                        bufnr = e.buf,
                        async = false,
                        timeout_ms = 10000,
                })
        end

        vim.api.nvim_create_autocmd('BufWritePre', {
                buffer = event.buf,
                group = fmt_group,
                desc = 'Format current buffer',
                callback = buf_format,
        })
end


vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'Setup format on save',
        callback = setup_autoformat,
})
