vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
})

vim.lsp.enable({ "lua_ls", "bashls", "" })

require("mason").setup()

vim.diagnostic.config({
  -- virtual_text = true,
})

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Set up completions',
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})
