vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

require "plugins.dap"

if vim.fn.has "win32" == 1 then
  -- Option 1: Using the 8.3 short path to avoid "Program Files" space issues
  vim.opt.shell = "C:/PROGRA~1/Git/bin/bash.exe"

  -- Option 2: If you prefer the full path, use backslash-escaped spaces:
  -- vim.opt.shell = "C:/Program\\ Files/Git/bin/bash.exe"

  -- These flags ensure bash starts as an interactive login shell
  vim.opt.shellcmdflag = "-i -l -c"

  -- Essential for redirecting output correctly in a Bash environment on Windows
  vim.opt.shellredir = ">%s 2>&1"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""

  -- Recommended for forward-slash compatibility in internal commands
  vim.opt.shellslash = true
end
