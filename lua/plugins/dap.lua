return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require "dap"
    local dapui = require "dapui"

    -- Initialize the UI
    dapui.setup()

    -- ========== C# CONFIGURATION ==========
    -- 1. Setup the Adapter
    dap.adapters.coreclr = {
      type = "executable",
      command = vim.fn.stdpath "data" .. "/mason/bin/netcoredbg",
      args = { "--interpreter=vscode" },
    }

    -- 2. Setup the Configuration with the DLL Finder
    dap.configurations.cs = {
      {
        type = "coreclr",
        name = "NetCoreDbg: Auto-Detect DLL",
        request = "launch",
        -- Correct logic: launch the dotnet host with the found DLL as an argument
        program = "dotnet",
        args = function()
          local file_path = vim.fn.expand "%:p"
          print("Building " .. vim.fn.expand "%:t" .. "...")

          -- 1. Run build and capture the "Project -> /path/to/dll" line
          local output = vim.fn.systemlist("dotnet build -c Debug " .. file_path)
          local dll_path = nil

          for _, line in ipairs(output) do
            -- Pattern matches the arrow '->' and captures the absolute path to the .dll
            local match = string.match(line, "%s%->%s(.+%.dll)$")
            if match then
              dll_path = match
              break
            end
          end

          -- 2. Validate and Return
          if dll_path and vim.fn.filereadable(dll_path) == 1 then
            print("Debugging: " .. dll_path)
            return { dll_path }
          else
            -- Fallback if parsing fails
            return { vim.fn.input("Build failed or DLL not found. Path: ", vim.fn.getcwd() .. "/bin/Debug/", "file") }
          end
        end,
        cwd = "${fileDirname}",
        stopAtEntry = false,
        env = {
          ASPNETCORE_ENVIRONMENT = "Development",
          DOTNET_MODIFIABLE_ASSEMBLIES = "debug",
        },
      },
    }

    --  Setup UI Automation
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
