vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
})

local servers = {
    "lua_ls",
    "bashls",
    "vtsls",
}

vim.lsp.enable(servers)

require("mason").setup()

require("mason-lspconfig").setup({
    automatic_enable = false,
    ensure_installed = servers,
})

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
        },
        linehl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
            [vim.diagnostic.severity.WARN] = "DiagnosticLineWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticLineInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticLineHint",
        },
    },
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end

        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
        end

        -- [Zed] Hover aliases.
        if client:supports_method("textDocument/hover") then
            map("n", "gh", vim.lsp.buf.hover, "[Zed] Hover")
        end

        -- [Zed] Code actions and symbol navigation aliases.
        if client:supports_method("textDocument/codeAction") then
            map({ "n", "x" }, "g.", vim.lsp.buf.code_action, "[Zed] Code actions")
        end
        if client:supports_method("textDocument/definition") then
            map("n", "gd", vim.lsp.buf.definition, "[Zed] Go to definition")
        end
        if client:supports_method("textDocument/declaration") then
            map("n", "gD", vim.lsp.buf.declaration, "[Zed] Go to declaration")
        end
        if client:supports_method("textDocument/typeDefinition") then
            map("n", "gy", vim.lsp.buf.type_definition, "[Zed] Go to type definition")
        end
        if client:supports_method("textDocument/implementation") then
            map("n", "gI", vim.lsp.buf.implementation, "[Zed] Go to implementation")
        end
        if client:supports_method("textDocument/references") then
            map("n", "gA", vim.lsp.buf.references, "[Zed] Find references")
        end

        -- [Zed] Diagnostic navigation alias.
        map("n", "g[", function()
            vim.diagnostic.jump({ count = -1, float = true })
        end, "[Zed] Previous diagnostic")
    end,
})

-- local fmt_group = vim.api.nvim_create_augroup('autoformat_cmds', { clear = true })

-- local function setup_autoformat(event)
--   local id = vim.tbl_get(event, 'data', 'client_id')
--   local client = id and vim.lsp.get_client_by_id(id)
--   if client == nil then
--     return
--   end

--   vim.api.nvim_clear_autocmds({ group = fmt_group, buffer = event.buf })

--   local buf_format = function(e)
--     vim.lsp.buf.format({
--       bufnr = e.buf,
--       async = false,
--       timeout_ms = 10000,
--     })
--   end

--   vim.api.nvim_create_autocmd('BufWritePre', {
--     buffer = event.buf,
--     group = fmt_group,
--     desc = 'Format current buffer',
--     callback = buf_format,
--   })
-- end


-- vim.api.nvim_create_autocmd('LspAttach', {
--   desc = 'Setup format on save',
--   callback = setup_autoformat,
-- })
