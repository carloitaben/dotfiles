return {
  settings = {
    Lua = {
      telemetry = {
        enable = false
      },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
}
