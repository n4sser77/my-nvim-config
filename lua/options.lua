require "nvchad.options"

-- add yours here!

local o = vim.o
o.cursorlineopt ='both' -- to enable cursorline!

-- Indentation: 4 spaces (VS Studio default, matches .editorconfig)
-- expandtab = true means use spaces instead of tabs
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
