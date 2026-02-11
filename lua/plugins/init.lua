return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  { import = "nvchad.blink.lazyspec" },

  -- 2. CONFIGURE BLINK FOR C# NUGETS

  {
    "saghen/blink.cmp",
    dependencies = { "GustavEikaas/easy-dotnet.nvim" },
    opts = function(_, opts)
      -- Setup the "provider" (where Blink gets data from)
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers["easy-dotnet"] = {
        name = "easy-dotnet",
        module = "easy-dotnet.completion.blink",
        score_offset = 10000, -- High score so it shows up at top
        async = true,
      }

      -- Add it to the list of active sources
      opts.sources.default = opts.sources.default or {}
      table.insert(opts.sources.default, "easy-dotnet")

      return opts
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "typescript",
        "tsx",
        -- C# development
        "c_sharp",
        "xml",
        "json",
        "yaml",
      },
    },
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    -- ✅ FIX 1: Explicitly load on TS/TSX filetypes
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    config = function()
      -- ✅ FIX 2: Get standard capabilities + Blink capabilities
      local capabilities = require("nvchad.configs.lspconfig").capabilities
      local has_blink, blink = pcall(require, "blink.cmp")
      if has_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      require("typescript-tools").setup {
        -- ✅ FIX 3: Pass capabilities to the plugin
        capabilities = capabilities,
        settings = {
          tsserver_file_preferences = {
            includeInlayParameterNameHints = "all",
            includeInlayFunctionParameterTypeHints = true,
            -- ... your other settings ...
          },
        },
        on_attach = function(client, bufnr)
          -- Use nvchad's default on_attach
          require("nvchad.configs.lspconfig").on_attach(client, bufnr)

          -- Auto-organize imports on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.cmd "TSToolsOrganizeImports"
              vim.cmd "TSToolsRemoveUnused"
            end,
          })
        end,
      }
    end,
  },

  -- Auto-close JSX/TSX tags
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        ["html"] = {
          enable_close = true,
        },
      },
    },
  },

  -- Smart commenting for JSX (// in JS, {/* */} in JSX)
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    event = "VeryLazy",
    opts = {
      enable_autocmd = false,
    },
    init = function()
      vim.g.skip_ts_context_commentstring_module = true
    end,
  },

  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    config = function()
      local capabilities = require("nvchad.configs.lspconfig").capabilities
      local has_blink, blink = pcall(require, "blink.cmp")
      if has_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      require("roslyn").setup {
        config = {
          capabilities = capabilities,
          on_attach = require("nvchad.configs.lspconfig").on_attach,
        },
      }
    end,
  },
  {
    "williamboman/mason.nvim",
    -- ✅ FIX 4: Use function to extend opts instead of replacing them
    opts = function(_, opts)
      opts.registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      }

      -- Ensure the TS server is actually installed
      opts.ensure_installed = opts.ensure_installed or {}
      local necessary_servers = { "typescript-language-server", "html-lsp", "css-lsp" }

      for _, server in ipairs(necessary_servers) do
        if not vim.tbl_contains(opts.ensure_installed, server) then
          table.insert(opts.ensure_installed, server)
        end
      end

      return opts
    end,
  },
  {
    "mfussenegger/nvim-dap",
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("dapui").setup()
    end,
  },
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local dotnet = require "easy-dotnet"

      dotnet.setup {
        -- 1. Disabling conflicts (Correct)
        lsp = { enabled = false },
        debugger = { auto_register_dap = false },

        -- 2. Test Runner (Correct)
        test_runner = {
          viewmode = "float",
          enable_buffer_test_execution = true,
          noBuild = true, -- Great choice for manual workflow
          mappings = {
            run_test_from_buffer = { lhs = "<leader>r", desc = "Run test from buffer" },
            filter_failed_tests = { lhs = "<leader>fe", desc = "Filter failed tests" },
            debug_test = { lhs = "<leader>d", desc = "Debug test" },
          },
        },

        -- 3. Modern C# Setup (Correct)
        auto_bootstrap_namespace = {
          type = "file_scoped",
          enabled = true,
        },

        -- 4. Terminal Handler (Correct)
        terminal = function(path, action, args)
          local commands = {
            run = function()
              return "dotnet run --project " .. path .. " " .. args
            end,
            test = function()
              return "dotnet test " .. path .. " " .. args
            end,
            restore = function()
              return "dotnet restore " .. path .. " " .. args
            end,
            build = function()
              return "dotnet build " .. path .. " " .. args
            end,
          }
          vim.cmd "vsplit"
          vim.cmd("term " .. commands[action]())
        end,
      }
    end,
  },

  -- Resu.nvim for reviewing AI-generated changes
  {
    "koushikxd/resu.nvim",
    dependencies = {
      "sindrets/diffview.nvim",
    },
    cmd = {
      "ResuOpen",
      "ResuClose",
      "ResuToggle",
      "ResuRefresh",
      "ResuAccept",
      "ResuDecline",
      "ResuAcceptAll",
      "ResuDeclineAll",
      "ResuReset",
    },
    keys = {
      { "<leader>rt", "<cmd>ResuToggle<cr>", desc = "Resu: Toggle review" },
      { "<leader>ra", "<cmd>ResuAccept<cr>", desc = "Resu: Accept changes" },
      { "<leader>rd", "<cmd>ResuDecline<cr>", desc = "Resu: Decline changes" },
      { "<leader>rA", "<cmd>ResuAcceptAll<cr>", desc = "Resu: Accept all" },
      { "<leader>rD", "<cmd>ResuDeclineAll<cr>", desc = "Resu: Decline all" },
      { "<leader>rr", "<cmd>ResuRefresh<cr>", desc = "Resu: Refresh" },
    },
    config = function()
      require("resu").setup {
        use_diffview = true,
        hot_reload = true,
        debounce_ms = 100,
        watch_dir = nil,
        ignored_files = {
          "%.git/",
          "node_modules/",
          "dist/",
          "build/",
          "%.DS_Store",
          "%.swp",
          "lazy%-lock%.json",
        },
        keymaps = {
          toggle = "<leader>rt",
          accept = "<leader>ra",
          decline = "<leader>rd",
          accept_all = "<leader>rA",
          decline_all = "<leader>rD",
          refresh = "<leader>rr",
          quit = "q",
        },
      }
    end,
  },
}
