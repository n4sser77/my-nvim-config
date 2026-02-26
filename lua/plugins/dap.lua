return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require "dap"
    local dapui = require "dapui"

    dapui.setup()

    local netcoredbg_bin = vim.fn.exepath "netcoredbg"
    if netcoredbg_bin == "" then
      netcoredbg_bin = "netcoredbg"
    end

    dap.adapters.coreclr = {
      type = "executable",
      command = netcoredbg_bin,
      args = { "--interpreter=vscode" },
    }

    -- =========================================================
    -- CONFIGURATIONS
    -- =========================================================
    dap.configurations.cs = {

      -- Single File Debugging (no plugin supports this)
      {
        type = "coreclr",
        name = "Single File Debug",
        request = "launch",
        console = "internalConsole",
        program = function()
          local output = vim.fn.systemlist("dotnet build -c Debug " .. vim.fn.shellescape(vim.fn.expand "%:p"))
          for _, line in ipairs(output) do
            local match = string.match(line, "%s%->%s(.+%.dll)$")
            if match then
              return match:gsub("^%s*(.-)%s*$", "%1")
            end
          end
          return vim.fn.input("DLL path: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
        end,
        cwd = "${fileDirname}",
      },

      -- Attach to Process
      {
        type = "coreclr",
        name = "Attach to process",
        request = "attach",
        processId = require("dap.utils").pick_process,
      },
    }

    -- UI Listeners
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
  end,
}
