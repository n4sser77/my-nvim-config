return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    {
      "mxsdev/nvim-dap-vscode-js",
      dependencies = {
        -- JavaScript debugger from Microsoft
        "microsoft/vscode-js-debug",
        -- Only build the extension, skip Playwright browser installation
        build = "npm install --legacy-peer-deps --ignore-scripts && npx gulp vsDebugServerBundle && mv dist out",
      },
    },
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
      -- =========================================================
      -- A. PROJECT DEBUGGING (Dynamic & Smart)
      -- =========================================================

      {
        type = "coreclr",
        name = "NetCoreDbg: Debug Project",
        request = "launch",
        program = "dotnet",

        -- 1. Dynamic CWD: Ensures the app runs from the project root (where .csproj is)
        --    so it can find appsettings.json, etc.
        cwd = function()
          local file_dir = vim.fn.expand "%:p:h"
          local root_file = vim.fs.find(function(name)
            return name:match "%.csproj$"
          end, { upward = true, path = file_dir })[1]

          return root_file and vim.fn.fnamemodify(root_file, ":p:h") or vim.fn.getcwd()
        end,

        -- 2. Build & Find DLL: Looks upward for .csproj, builds it, and asks CLI for the DLL path
        args = function()
          -- A. Find the Project Root (Anchor)
          local file_dir = vim.fn.expand "%:p:h"
          local root_file = vim.fs.find(function(name)
            return name:match "%.csproj$"
          end, { upward = true, path = file_dir })[1]

          if not root_file then
            return { vim.fn.input("No .csproj found. Manual path: ", vim.fn.getcwd() .. "/bin/Debug/", "file") }
          end

          local project_root = vim.fn.fnamemodify(root_file, ":p:h")
          print("🛠️  Building Project: " .. project_root)

          -- B. Ask the CLI: "Build this and tell me the TargetPath"
          --    We run this command INSIDE the project root.
          local cmd = "dotnet build -c Debug --getProperty:TargetPath"
          local output = vim.fn.systemlist(cmd, project_root)

          -- C. Parse the output (Source of Truth)
          for _, line in ipairs(output) do
            -- Clean the line (remove whitespace/newlines)
            local path = line:gsub("^%s*(.-)%s*$", "%1")
            if path:match "%.dll$" or path:match "%.exe$" then
              print("🚀 Launching: " .. path)
              return { path }
            end
          end

          return { vim.fn.input("Build failed. Manual path: ", project_root .. "/bin/Debug/", "file") }
        end,

        env = {
          ASPNETCORE_ENVIRONMENT = "Development",
        },
      },

      -- =========================================================
      -- B. SINGLE FILE DEBUGGING (Your existing logic)
      -- =========================================================
      {
        type = "coreclr",
        name = "NetCoreDbg: Single File App",
        request = "launch",
        program = "dotnet",
        args = function()
          local file_path = vim.fn.expand "%:p"
          print("🛠️  Building Single File " .. vim.fn.expand "%:t" .. "...")

          -- Run build and capture the "Project -> /path/to/dll" line
          local output = vim.fn.systemlist("dotnet build -c Debug " .. vim.fn.shellescape(file_path))
          local dll_path = nil

          for _, line in ipairs(output) do
            -- Pattern matches the arrow '->' and captures the absolute path to the .dll
            local match = string.match(line, "%s%->%s(.+%.dll)$")
            if match then
              dll_path = match
              break
            end
          end

          if dll_path and vim.fn.filereadable(dll_path) == 1 then
            print("🚀 Launching: " .. dll_path)
            return { dll_path }
          else
            return { vim.fn.input("Build failed. Manual path: ", vim.fn.getcwd() .. "/bin/Debug/", "file") }
          end
        end,
        cwd = "${fileDirname}",
        stopAtEntry = false,
      },
      -- =========================================================
      -- 3. CONFIGURATION FOR WATCH (Hot Reload / Attach)
      -- =========================================================
      {
        type = "coreclr",
        name = "🔥 Attach to running process (dotnet watch)",
        request = "attach",
        processId = function()
          -- Vi använder ett hjälpverktyg från nvim-dap för att lista processer
          -- Detta kräver att du har 'pickers' (t.ex. telescope eller inbyggd)
          local utils = require "dap.utils"

          return utils.pick_process {
            filter = function(proc)
              -- Visa bara processer som innehåller "dotnet" eller namnet på din app
              -- Oftast heter processen bara "dotnet" när man kör "dotnet watch"
              return proc.name:match "dotnet"
            end,
          }
        end,
        -- Valfritt: Om du vill att debuggern ska mappa källkoden rätt automatiskt
        cwd = "${fileDirname}",
      },
    }

    -- ========== TYPESCRIPT/JAVASCRIPT CONFIGURATION ==========
    -- Setup vscode-js-debug adapter
    require("dap-vscode-js").setup {
      -- Path to vscode-js-debug installation
      debugger_path = vim.fn.stdpath "data" .. "/lazy/vscode-js-debug",
      -- Which adapters to use
      adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
    }

    -- TypeScript/JavaScript configurations
    for _, language in ipairs { "typescript", "javascript", "typescriptreact", "javascriptreact" } do
      dap.configurations[language] = {
        -- Debug current file with Node.js
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch Current File (Node)",
          program = "${file}",
          cwd = "${workspaceFolder}",
          runtimeExecutable = "node",
          args = { "--inspect-brk", "${file}" },
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
          skipFiles = { "<node_internals>/**", "node_modules/**" },
        },
        -- Attach to running Node.js process
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to Node Process",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        -- Debug with Chrome (for frontend apps)
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome (Debug)",
          url = "http://localhost:3000",
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
          protocol = "inspector",
          port = 9222,
          skipFiles = { "<node_internals>/**", "node_modules/**" },
        },
        -- Debug with npm run dev
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug npm run dev",
          runtimeExecutable = "npm",
          runtimeArgs = { "run", "dev" },
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          sourceMaps = true,
        },
        -- Debug with yarn dev
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug yarn dev",
          runtimeExecutable = "yarn",
          runtimeArgs = { "dev" },
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          sourceMaps = true,
        },
      }
    end

    -- 3. Setup UI Automation
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
