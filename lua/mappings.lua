require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- ============================================================
-- Diagnostic Navigation
-- ============================================================
map("n", "]d", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next diagnostic error" })
map("n", "[d", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous diagnostic error" })
map("n", "]w", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Next diagnostic warning" })
map("n", "[w", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Previous diagnostic warning" })

-- Show all diagnostics in floating window
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostics in float" })

-- ============================================================
-- Quickfix
-- ============================================================
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix window" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix window" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line down" })

map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
--
-- Toggle relative numbers
map("n", "<A-r>", function()
  vim.o.relativenumber = not vim.o.relativenumber
end, { desc = "Toggle relative numbers" })

-- Debugging Mappings
map("n", "<F5>", function()
  require("dap").continue()
end, { desc = "Debug: Start/Continue" })
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Debug: Toggle Breakpoint" })

-- Stepping
map("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "Debug: Step Over" })
map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "Debug: Step Into" })
map("n", "<leader>dO", function()
  require("dap").step_out()
end, { desc = "Debug: Step Out" })

-- UI Control
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Debug: Toggle UI" })

-- Easy-Dotnet Mappings
map("n", "<leader>nt", function()
  require("easy-dotnet").test_runner()
end, { desc = "Dotnet Test Runner" })
map("n", "<leader>np", function()
  require("easy-dotnet").project_view()
end, { desc = "Solution Explorer" })
map("n", "<leader>ns", function()
  require("easy-dotnet").secrets()
end, { desc = "Edit Secrets" })
map("n", "<leader>no", function()
  require("easy-dotnet").outdated()
end, { desc = "Check Outdated Packages" })

-- TypeScript-specific Keymaps
map("n", "<leader>co", "<cmd>TSToolsOrganizeImports<cr>", { desc = "TS: Organize imports" })
map("n", "<leader>ci", "<cmd>TSToolsAddMissingImports<cr>", { desc = "TS: Add missing imports" })
map("n", "<leader>cu", "<cmd>TSToolsRemoveUnused<cr>", { desc = "TS: Remove unused imports" })
map("n", "<leader>cf", "<cmd>TSToolsFixAll<cr>", { desc = "TS: Fix all diagnostics" })
map("n", "<leader>cg", "<cmd>TSToolsGoToSourceDefinition<cr>", { desc = "TS: Go to source definition" })
map("n", "<leader>cR", "<cmd>TSToolsRenameFile<cr>", { desc = "TS: Rename file and update imports" })
