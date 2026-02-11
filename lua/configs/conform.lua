local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "biome" },
    html = { "biome" },
    typescript = { "biome" },
    typescriptreact = { "biome" },
    javascript = { "biome" },
    javascriptreact = { "biome" },
    -- csharp: Use LSP (Roslyn) for formatting via lsp_fallback
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
