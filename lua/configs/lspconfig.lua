require("nvchad.configs.lspconfig").defaults()

local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities

-- ============================================================
-- Modern Diagnostics Configuration (Neovim 0.12+)
-- Using underlines + signs + float window
-- ============================================================

-- Define diagnostic signs (shown in gutter)
local signs = { Error = "✗ ", Warn = "⚠ ", Hint = "➤ ", Info = "ℹ " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- VS Code style: Red squiggly underlines for errors only
-- Other severities use regular underlines
vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
  fg = "#ff3333",
  sp = "#ff3333",
  undercurl = true, -- Squiggly line (requires terminal support)
})

-- Other severities: regular underlines with severity colors
vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", {
  sp = "#ffd93d",
  undercurl = false,
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", {
  sp = "#6bcfff",
  undercurl = false,
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", {
  sp = "#a8e6cf",
  undercurl = false,
})

-- Float window configuration (for :vim.diagnostic.open_float)
vim.diagnostic.config({
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },

  -- Enable underlines (for VS Code style squiggly lines)
  underline = true,

  -- Only show virtual text for errors, not warnings/info
  virtual_text = {
    severity = { min = vim.diagnostic.severity.ERROR },
  },

  -- Don't update while typing (performance)
  update_in_insert = false,

  -- Sort by severity (errors first)
  severity_sort = true,

  -- Note: virtual_text and virtual_lines are configured here
})

-- ============================================================
-- LSP Servers Configuration
-- ============================================================

-- blink.cmp capabilities
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

-- LSP Servers configuration using vim.lsp.config (Neovim 0.11+)
local servers = { "html", "cssls", "jsonls", "markdown_oxide" }

for _, lsp in ipairs(servers) do
  -- Specifik konfiguration för JSON
  local config = {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {}, -- Initiera tom settings
  }

  if lsp == "jsonls" then
    -- Kolla om SchemaStore finns installerat
    local has_schemastore, schemastore = pcall(require, "schemastore")
    config.settings = {
      json = {
        schemas = has_schemastore and schemastore.json.schemas() or {},
        validate = { enable = true },
      },
    }
  end

  if lsp == "markdown_oxide" then
    config.capabilities = vim.tbl_deep_extend("force", capabilities, {
      workspace = {
        didChangeWatchedFiles = { dynamicRegistration = true },
      },
    })
  end

  -- Define the LSP configuration using vim.lsp.config
  vim.lsp.config[lsp] = config

  -- Enable the LSP server
  vim.lsp.enable(lsp)
end

-- Roslyn.nvim configuration
-- Use vim.lsp.config to extend (not replace) the plugin's defaults
vim.lsp.config("roslyn", {
    on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- Merge blink.cmp capabilities if available
        local has_blink, blink = pcall(require, "blink.cmp")
        if has_blink then
            client.capabilities = vim.tbl_deep_extend("force", client.capabilities, blink.get_lsp_capabilities({}))
        end
        -- Fix: Roslyn returns prepareProvider: null which breaks rename in Neovim
        -- Roslyn supports rename but not prepareRename, so we fix the capability
        if client.name == "roslyn" then
            client.server_capabilities.renameProvider = true
        end
    end,
})
