return {
    -- EditorConfig support - reads .editorconfig files and applies settings
    {
        "gpanders/editorconfig.nvim",
        priority = 1000, -- Load early to set buffer options
    },

    -- LSP Lines - Shows diagnostics as virtual lines below code (VS Code style)
    -- DISABLED: Using underlines + signs instead
    {
        "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
        event = "LspAttach",
        enabled = false,
    },

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

    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
        event = "FileType markdown",
        config = function()
            require("render-markdown").setup {
                code = {
                    enabled = true,
                    renderer = "treesitter",
                },
            }
        end,
    },

    {
        "b0o/SchemaStore.nvim",
        lazy = true, -- Den laddas när den behövs
    },

    -- 2. CONFIGURE BLINK FOR C# NUGETS
    -- This extends the NvChad blink.cmp config loaded via nvchad.blink.lazyspec
    {
        "saghen/blink.cmp",
        dependencies = { "GustavEikaas/easy-dotnet.nvim" },
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            opts.sources.providers = opts.sources.providers or {}
            opts.sources.providers["easy-dotnet"] = {
                name = "easy-dotnet",
                module = "easy-dotnet.completion.blink",
                score_offset = 10000,
                async = true,
            }
            opts.sources.default = opts.sources.default or {}
            table.insert(opts.sources.default, "easy-dotnet")
            return opts
        end,
    },

    -- AI Code Completion with local LLM (Ollama via Minuet)
    {
        "milanglacier/minuet-ai.nvim",
        dependencies = { "saghen/blink.cmp" },
        opts = {
            providers = {
                ollama = {
                    module = "minuet.providers.ollama",
                    name = "Ollama",
                    opts = {
                        model = "qwen2.5-coder:0.5b",
                        url = "http://localhost:11434",
                    },
                },
            },
            -- ENABLE VIRTUAL TEXT (ghost text)
            virtualtext = {
                enabled = true,
                auto_trigger_ft = { "cs", "csharp", "javascript", "typescript", "python", "lua", "go", "rust", "java" },
                keymap = {
                    accept = "<Tab>",
                    accept_line = "<S-Tab>",
                    dismiss = "<C-x>",
                    next = "<A-]>",
                    prev = "<A-[>",
                },
            },
            -- Blink cmp integration
            sources = {
                default = { "ollama", "lsp", "path", "snippets", "buffer" },
            },
        },
    },

    -- Continue.dev for AI coding with MCP
    {
        "Megatherium/continue.nvim",
        lazy = false,
        submodules = false,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            -- 1. Lägg till dina mappar i ignored_dirs (fixad syntax med '=')
            opts.filesystem_watchers = {
                enable = true,
                debounce_delay = 50,
                ignored_dirs = {
                    "bin",
                    "obj",
                    "%.git",
                    "node_modules",
                },
            }

            -- 2. Lägg till dina språk i listan istället för att skriva över den
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, {
                    -- Core
                    "vim",
                    "lua",
                    "vimdoc",
                    -- Web
                    "html",
                    "css",
                    "typescript",
                    "tsx",
                    "javascript",
                    "json",
                    "yaml",
                    -- .NET
                    "c_sharp",
                    "xml",
                    "razor",
                    -- Markdown
                    "markdown",
                    "markdown_inline",
                    -- Shell/Scripts
                    "bash",
                    "powershell",
                    "python",
                    -- Config files
                    "dockerfile",
                    "nginx",
                    "toml",
                    "ini",
                    "dotenv",
                    -- Data
                    "sql",
                    "graphql",
                })
            else
                -- Om listan inte finns sen tidigare (ovanligt i LazyVim)
                opts.ensure_installed = {
                    -- Core
                    "vim",
                    "lua",
                    "vimdoc",
                    -- Web
                    "html",
                    "css",
                    "typescript",
                    "tsx",
                    "javascript",
                    "json",
                    "yaml",
                    -- .NET
                    "c_sharp",
                    "xml",
                    "razor",
                    -- Markdown
                    "markdown",
                    "markdown_inline",
                    -- Shell/Scripts
                    "bash",
                    "powershell",
                    "python",
                    -- Config files
                    "dockerfile",
                    "nginx",
                    "toml",
                    "ini",
                    "dotenv",
                    -- Data
                    "sql",
                    "graphql",
                }
            end

            -- 3. Aktivera highlight (behåller default för övriga highlight-options)
            opts.highlight = opts.highlight or {}
            opts.highlight.enable = true
            opts.highlight.additional_vim_regex_highlighting = { "razor" }
        end,
    },

    {
        "nvim-telescope/telescope.nvim",
        opts = function(_, opts)
            opts.defaults = opts.defaults or {}
            opts.defaults.hidden = true -- Visa dolda filer (dotfiles)
            opts.defaults.no_ignore = true -- Sök även i filer som ignoreras av .gitignore

            -- Filtrera bort "clutter" manuellt med Lua regex
            opts.defaults.file_ignore_patterns = {
                "%.git/", -- Ignorerar hela .git-mappen
                "node_modules/", -- Ignorerar node_modules
                "%.idea/", -- JetBrains/IntelliJ filer
                "%.vscode/", -- VS Code inställningar
                "%.DS_Store", -- macOS systemfiler
                "target/", -- Rust/Java build-filer
                "build/", -- Allmänna build-mappar
                "dist/", -- Distribution-filer
            }

            opts.pickers = opts.pickers or {}
            opts.pickers.find_files = {
                hidden = true,
                -- no_ignore = false, -- Tips: Sätt till false om du vill att .gitignore ska gälla här
            }

            return opts
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        opts = function(_, opts)
            -- Vi behåller allt NvChad har ställt in, men ändrar bara filtren
            opts.filters = opts.filters or {}
            opts.filters.dotfiles = false
            opts.filters.git_ignored = false

            -- Om du vill dölja specifika mappar ändå:
            opts.filters.custom = { "node_modules" }

            return opts
        end,
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
        opts = {},
    },
    {
        "williamboman/mason.nvim",
        -- ✅ FIX 4: Use function to extend opts instead of replacing them
        opts = function(_, opts)
            opts.registries = {
                "github:mason-org/mason-registry",
                "github:Crashdummyy/mason-registry",
            }

            -- Ensure all tools are installed on every machine
            opts.ensure_installed = opts.ensure_installed or {}
            local necessary_servers = {
                -- JS/TS
                "typescript-language-server",
                "html-lsp",
                "css-lsp",
                "biome",
                -- JSON
                "json-lsp",
                "prettier",
                -- XML
                "lemminx",
                -- Lua
                "lua-language-server",
                "stylua",
                -- Markdown
                "markdown-oxide",
                -- C# / .NET
                "netcoredbg",
            }

            for _, server in ipairs(necessary_servers) do
                if not vim.tbl_contains(opts.ensure_installed, server) then
                    table.insert(opts.ensure_installed, server)
                end
            end

            return opts
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
                debugger = {
                    auto_register_dap = true,
                },

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
