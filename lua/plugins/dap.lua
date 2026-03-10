return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    "GustavEikaas/easy-dotnet.nvim",
  },
  config = function()
    local dap = require("dap")
    dap.set_log_level("TRACE")
    local dapui = require("dapui")

    dapui.setup({
      expand_lines = true,
      layouts = {
        {
          elements = {
            { id = "scopes",      size = 0.40 },
            { id = "watches",     size = 0.20 },
            { id = "breakpoints", size = 0.20 },
            { id = "stacks",      size = 0.20 },
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl",    size = 0.7 },
            { id = "console", size = 0.3 },
          },
          size = 12,
          position = "bottom",
        },
      },
    })

    local ok_netcoredbg, netcoredbg = pcall(require, "easy-dotnet.netcoredbg")
    if ok_netcoredbg then
      netcoredbg.register_dap_variables_viewer()
    end

    dap.adapters.coreclr = {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
      args = { "--interpreter=vscode" },
    }

    require("nvim-dap-virtual-text").setup {
      enabled = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      show_stop_reason = true,
      all_frames = false,
      virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
      display_callback = function(variable, _, _, _, _)
        local val = variable.value
        if #val > 80 then val = val:sub(1, 77) .. "..." end
        return " = " .. val
      end,
    }

    dap.listeners.on_config["dotnet_justmycode"] = function(config)
      if config.type == "easy-dotnet" or config.type == "coreclr" then
        if config.justMyCode == nil then
          config.justMyCode = false
        end
        if config.requireExactSource == nil then
          config.requireExactSource = false
        end
      end
      return config
    end

    dap.listeners.after.event_initialized.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    dap.defaults.fallback.initialize_timeout_sec = 60
    dap.defaults.fallback.disconnect_timeout_sec = 5

    local function parse_args(arg_string)
      local args = {}
      local s = arg_string
      local i = 1

      while i <= #s do
        local ws = s:find("[^%s]", i)
        if not ws then break end
        i = ws

        if s:sub(i, i) == '"' then
          local close = s:find('"', i + 1, true)
          if close then
            args[#args + 1] = s:sub(i + 1, close - 1)
            i = close + 1
          else
            args[#args + 1] = s:sub(i + 1)
            break
          end
        else
          local token_end = s:find("%s", i)
          if token_end then
            args[#args + 1] = s:sub(i, token_end - 1)
            i = token_end
          else
            args[#args + 1] = s:sub(i)
            break
          end
        end
      end

      if args[1] == "--" then
        table.remove(args, 1)
      end

      return args
    end

    vim.keymap.set("n", "<F5>", function()
      if dap.session() then
        dap.continue()
        return
      end
      require("configs.dotnet-debug").pick_and_prepare(function(dll, args, env, cwd)
        dapui.open()
        vim.schedule(function()
          dap.run({
            type    = "coreclr",
            name    = "Launch .NET",
            request = "launch",
            program = dll,
            args    = args,
            env     = env,
            cwd     = cwd,
            console = "integratedTerminal",
          })
        end)
      end)
    end, { desc = "Start/continue debugging" })
    vim.keymap.set("n", "<F10>", dap.step_over,  { desc = "Step over" })
    vim.keymap.set("n", "<F11>",      dap.step_into,        { desc = "Step into" })
    vim.keymap.set("n", "<F12>",      dap.step_out,         { desc = "Step out" })
    vim.keymap.set("n", "<leader>b",  dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<leader>dr", dap.repl.toggle,      { desc = "Toggle DAP REPL" })
    vim.keymap.set("n", "<leader>dj", dap.down,             { desc = "Go down stack frame" })
    vim.keymap.set("n", "<leader>dk", dap.up,               { desc = "Go up stack frame" })
    vim.keymap.set("n", "q", function()
      dap.terminate()
      dap.clear_breakpoints()
    end, { desc = "Terminate and clear breakpoints" })
    vim.keymap.set("n", "<leader>ds", function()
      local bps = require("dap.breakpoints").get()
      local count = 0
      for _, file_bps in pairs(bps) do count = count + #file_bps end
      vim.notify("nvim-dap has " .. count .. " breakpoint(s) registered", vim.log.levels.INFO)
    end, { desc = "Debug: Show registered breakpoint count" })
    vim.keymap.set("n", "<leader>dl", function()
      vim.cmd("edit " .. vim.fn.stdpath("cache") .. "/dap.log")
    end, { desc = "Debug: Open DAP log" })
    vim.keymap.set("n", "<leader>dX", function()
      dap.clear_breakpoints()
      vim.notify("All breakpoints cleared", vim.log.levels.INFO)
    end, { desc = "Debug: Clear all breakpoints" })

    vim.keymap.set("n", "<leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Condition: "))
    end, { desc = "Debug: Conditional breakpoint" })
    vim.keymap.set("n", "<leader>dL", function()
      dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
    end, { desc = "Debug: Log point" })

    vim.keymap.set("n", "<leader>dh", function() dapui.eval() end,
      { desc = "Debug: Hover eval (word under cursor)" })
    vim.keymap.set("v", "<leader>dh", function() dapui.eval() end,
      { desc = "Debug: Eval selection" })
    vim.keymap.set("n", "<leader>de", function()
      dapui.eval(vim.fn.input("Eval: "))
    end, { desc = "Debug: Eval expression" })

    vim.keymap.set("n", "<leader>da", function()
      vim.ui.input({ prompt = "Args: ", default = "" }, function(input)
        if input == nil then return end

        local args = parse_args(input)
        local ok, dll_path = pcall(require("configs.nvim-dap-dotnet").build_dll_path)
        if not ok then
          vim.notify("[dap] " .. dll_path, vim.log.levels.ERROR)
          return
        end

        dap.run({
          type = "coreclr",
          name = "Launch (with args)",
          request = "launch",
          program = dll_path,
          args = args,
          console = "integratedTerminal",
        })
      end)
    end, { desc = "Debug .NET with CLI args" })
  end,
}
