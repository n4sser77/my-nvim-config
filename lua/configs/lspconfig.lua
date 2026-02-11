require("nvchad.configs.lspconfig").defaults()

local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities

-- blink.cmp capabilities
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

-- LSP Servers configuration using vim.lsp.config (Neovim 0.11+)
local servers = { "html", "cssls" }

for _, lsp in ipairs(servers) do
  -- Define the LSP configuration using vim.lsp.config
  vim.lsp.config[lsp] = {
    capabilities = capabilities,
    on_attach = on_attach,
  }
  
  -- Enable the LSP server
  vim.lsp.enable(lsp)
end

-- Roslyn.nvim configuration
-- Note: roslyn.nvim is configured separately in plugins/init.lua
-- but we need to ensure it uses the correct capabilities
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("roslyn-lsp-attach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "roslyn" then
      -- Apply NvChad's on_attach for Roslyn
      on_attach(args.buf)
    end
  end,
})
