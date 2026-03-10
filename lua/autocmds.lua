require "nvchad.autocmds"

-- =========================
-- Language Parser Preload
-- =========================
-- Preload language parsers for markdown code block highlighting
-- This enables syntax highlighting in ```code blocks without needing to open those file types first
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local langs = {
      -- .NET
      "c_sharp",
      -- Web
      "javascript",
      "typescript",
      "html",
      "css",
      "json",
      "yaml",
      -- Scripts
      "bash",
      "python",
      "powershell",
      -- Data/Config
      "sql",
      "dockerfile",
      "toml",
      "lua",
      "graphql",
    }
    for _, lang in ipairs(langs) do
      pcall(vim.treesitter.language.add, lang, {})
    end
  end,
})

-- =========================
-- Filetype Detection
-- =========================
vim.filetype.add {
  extension = {
    razor = "razor",
    cshtml = "razor",
  },
}
