return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require "dap"
    local dapui = require "dapui"
    local is_windows = vim.loop.os_uname().version:match "Windows"

    dapui.setup()

    -- =========================================================
    -- 1. HJÄLPFUNKTIONER (LaunchSettings & Paths)
    -- =========================================================

    -- Hitta och parsa launchSettings.json säkert
    local function get_launch_settings()
      local current_buf_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
      local path = vim.fs.find("Properties/launchSettings.json", { upward = true, path = current_buf_dir })[1]

      if not path then
        path = vim.fs.find("Properties/launchSettings.json", { upward = true })[1]
      end

      if not path then
        return nil
      end

      local file = io.open(path, "r")
      if not file then
        return nil
      end
      local content = file:read "*a"
      file:close()

      -- OBS: Ingen regex-städning här för att inte förstöra http:// länkar
      local ok, result = pcall(vim.fn.json_decode, content)
      if not ok then
        vim.notify("Kunde inte läsa launchSettings.json. Är det giltig JSON?", vim.log.levels.ERROR)
        return nil
      end
      return result
    end

    -- Ladda miljövariabler interaktivt
    local function load_env_from_launch_settings()
      local env = {}
      env["ASPNETCORE_ENVIRONMENT"] = "Development" -- Default

      local settings = get_launch_settings()
      if not settings or not settings.profiles then
        vim.notify("Hittade inga profiler i launchSettings.json", vim.log.levels.WARN)
        return env
      end

      local profile_names = {}
      for name, data in pairs(settings.profiles) do
        if data.commandName == "Project" then
          table.insert(profile_names, name)
        end
      end
      table.sort(profile_names)

      if #profile_names == 0 then
        vim.notify("Inga 'Project'-profiler hittades.", vim.log.levels.WARN)
        return env
      end

      local options = { "Välj Launch Profile:" }
      for i, name in ipairs(profile_names) do
        table.insert(options, string.format("%d. %s", i, name))
      end

      local choice_index = vim.fn.inputlist(options)
      if choice_index < 1 then
        vim.notify("Profilval avbrutet. Kör standard.", vim.log.levels.INFO)
        return env
      end

      local selected_name = profile_names[choice_index]
      local profile = settings.profiles[selected_name]

      vim.notify("🚀 Vald profil: " .. selected_name, vim.log.levels.INFO)

      if profile.environmentVariables then
        for k, v in pairs(profile.environmentVariables) do
          env[k] = v
        end
      end

      if profile.applicationUrl then
        env["ASPNETCORE_URLS"] = profile.applicationUrl
      end

      return env
    end

    -- Sökväg till netcoredbg
    local function get_netcoredbg_path()
      local data_path = vim.fn.stdpath "data"
      if is_windows then
        local path = data_path .. "\\mason\\packages\\netcoredbg\\netcoredbg\\netcoredbg.exe"
        return path:gsub("/", "\\")
      else
        return data_path .. "/mason/bin/netcoredbg"
      end
    end

    -- =========================================================
    -- 2. ADAPTER DEFINITION
    -- =========================================================
    dap.adapters.coreclr = {
      type = "executable",
      command = get_netcoredbg_path(),
      args = { "--interpreter=vscode" },
    }

    -- =========================================================
    -- 3. CONFIGURATIONS
    -- =========================================================
    dap.configurations.cs = {

      -- 1. NY: Launch via Profile (ASP.NET)
      {
        type = "coreclr",
        name = "1. NetCoreDbg: Launch via Profile (ASP.NET)",
        request = "launch",
        console = "internalConsole",
        program = function()
          local root_file = vim.fs.find(function(name)
            return name:match "%.csproj$"
          end, { upward = true })[1]
          if not root_file then
            return vim.fn.input("DLL path: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end

          local cmd = "dotnet build -c Debug --getProperty:TargetPath " .. vim.fn.shellescape(root_file)
          local output = vim.fn.systemlist(cmd)
          for _, line in ipairs(output) do
            local p = line:gsub("^%s*(.-)%s*$", "%1")
            if p:match "%.dll$" or p:match "%.exe$" then
              return p
            end
          end
          return vim.fn.input("Build failed. DLL path: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
        end,
        cwd = function()
          local root = vim.fs.find({ ".csproj" }, { upward = true })[1]
          return root and vim.fs.dirname(root) or vim.fn.getcwd()
        end,
        env = function()
          return load_env_from_launch_settings()
        end,
      },

      -- 2. GAMMAL: Generic Debug Project
      {
        type = "coreclr",
        name = "2. NetCoreDbg: Debug Project (Generic)",
        request = "launch",
        console = "internalConsole",
        program = function()
          local root_file = vim.fs.find(function(name)
            return name:match "%.csproj$"
          end, { upward = true })[1]
          if not root_file then
            return vim.fn.input("DLL path: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end

          local cmd = "dotnet build -c Debug --getProperty:TargetPath " .. vim.fn.shellescape(root_file)
          local output = vim.fn.systemlist(cmd)
          for _, line in ipairs(output) do
            local p = line:gsub("^%s*(.-)%s*$", "%1")
            if p:match "%.dll$" or p:match "%.exe$" then
              return p
            end
          end
        end,
        cwd = function()
          local root = vim.fs.find({ ".csproj", ".sln" }, { upward = true })[1]
          return root and vim.fn.fnamemodify(root, ":p:h") or vim.fn.getcwd()
        end,
        env = { ASPNETCORE_ENVIRONMENT = "Development" },
      },

      -- 3. GAMMAL: Single File Debugging
      {
        type = "coreclr",
        name = "3. NetCoreDbg: Single File",
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

      -- 4. GAMMAL: Attach to Process
      {
        type = "coreclr",
        name = "4. 🔥 Attach to process",
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
