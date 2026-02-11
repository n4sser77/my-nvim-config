require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")


map("n","<A-j>",":m .+1<CR>==", {desc = "Move line down"})
map("n","<A-k>",":m .-2<CR>==",{desc = "Move line down"})

map("v","<A-j>",":m '>+1<CR>gv=gv", {desc = "Move selection down"})
map("v","<A-k>",":m '<-2<CR>gv=gv",{desc = "Move selection up"})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
--
-- Debugging Mappings 
map("n", "<F5>", function() require("dap").continue() end, { desc = "Debug: Start/Continue" })
map("n", "<F1>", function() require("dap").toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })

-- Stepping (Standard IDE keys)
map("n", "<F10>", function() require("dap").step_over() end, { desc = "Debug: Step Over" })
map("n", "<F11>", function() require("dap").step_into() end, { desc = "Debug: Step Into" })
map("n", "<F12>", function() require("dap").step_out() end, { desc = "Debug: Step Out" })

-- UI Control
map("n", "<leader>du", function() require("dapui").toggle() end, { desc = "Debug: Toggle UI" })

-- Easy-Dotnet Mappings
map("n", "<leader>nt", function() require("easy-dotnet").test_runner() end, { desc = "Dotnet Test Runner" })
map("n", "<leader>np", function() require("easy-dotnet").project_view() end, { desc = "Solution Explorer" })
map("n", "<leader>ns", function() require("easy-dotnet").secrets() end, { desc = "Edit Secrets" })
map("n", "<leader>no", function() require("easy-dotnet").outdated() end, { desc = "Check Outdated Packages" })

-- TypeScript-specific Keymaps
map("n", "<leader>co", "<cmd>TSToolsOrganizeImports<cr>", { desc = "TS: Organize imports" })
map("n", "<leader>ci", "<cmd>TSToolsAddMissingImports<cr>", { desc = "TS: Add missing imports" })
map("n", "<leader>cu", "<cmd>TSToolsRemoveUnused<cr>", { desc = "TS: Remove unused imports" })
map("n", "<leader>cf", "<cmd>TSToolsFixAll<cr>", { desc = "TS: Fix all diagnostics" })
map("n", "<leader>cg", "<cmd>TSToolsGoToSourceDefinition<cr>", { desc = "TS: Go to source definition" })
map("n", "<leader>cR", "<cmd>TSToolsRenameFile<cr>", { desc = "TS: Rename file and update imports" })


