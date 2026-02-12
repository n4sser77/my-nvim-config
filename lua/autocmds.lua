require "nvchad.autocmds"

-- Detect razor and cshtml files
vim.filetype.add {
  extension = {
    razor = "razor",
    cshtml = "razor",
  },
}
