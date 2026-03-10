-- dotnet-debug.lua
-- Custom .NET debug helper: replaces easy-dotnet's debug flow with pure Lua + shell commands.
-- Flow: find solution → pick project → build → pick launch profile → call on_ready(dll, args, env, cwd)
-- Uses netcoredbg in "launch" mode (netcoredbg starts the process itself, so args/env reach it).

local M = {}

-- ─── 1. SOLUTION DISCOVERY ────────────────────────────────────────────────────
-- Walk up from cwd until we find a .sln file.
-- Returns the absolute path to the .sln, or nil if not found.
local function find_solution()
  local dir = vim.fn.getcwd()
  while dir ~= "/" do
    local slns = vim.fn.glob(dir .. "/*.sln", false, true)
    if #slns > 0 then return slns[1] end
    dir = vim.fn.fnamemodify(dir, ":h") -- ":h" in Vim means "head" = parent directory
  end
  return nil
end

-- ─── 2. .SLN PARSER ───────────────────────────────────────────────────────────
-- A .sln file has lines like:
--   Project("{GUID}") = "MyApp", "src/MyApp/MyApp.csproj", "{GUID}"
-- We extract the .csproj relative path and resolve it to an absolute path.
local function parse_sln(sln_path)
  local sln_dir = vim.fn.fnamemodify(sln_path, ":h")
  local projects = {}
  for line in io.lines(sln_path) do
    -- Lua pattern: match the second quoted string that ends in .csproj
    local rel_path = line:match('".-", "(.-%.csproj)"')
    if rel_path then
      rel_path = rel_path:gsub("\\", "/") -- normalize Windows backslashes
      table.insert(projects, sln_dir .. "/" .. rel_path)
    end
  end
  return projects
end

-- ─── 3. GET EXACT DLL PATH ────────────────────────────────────────────────────
-- Uses `dotnet build --getProperty:TargetPath` to get the exact output .dll path.
-- Falls back to the heuristic in nvim-dap-dotnet.lua if the command fails.
local function get_dll_path(csproj_path, configuration)
  configuration = configuration or "Debug"
  -- Ask dotnet: "where will you put the built artifact?"
  -- --nologo = skip the copyright banner, -v:q = quiet output, 2>/dev/null = hide stderr
  local result = vim.fn.system(string.format(
    "dotnet build %q --configuration %s --getProperty:TargetPath --nologo -v:q 2>/dev/null",
    csproj_path, configuration
  ))
  -- The last line of output is the path
  local path = vim.trim(result):match("[^\n]+$")
  if path and vim.fn.filereadable(path) == 1 then
    return path
  end
  -- Fallback: use the glob-based heuristic
  return require("configs.nvim-dap-dotnet").build_dll_path()
end

-- ─── 4. BUILD THE PROJECT ─────────────────────────────────────────────────────
-- Runs `dotnet build` asynchronously using vim.fn.jobstart (non-blocking).
-- Calls on_done(true) on success, on_done(false) on failure.
local function build_project(csproj_path, on_done)
  local name = vim.fn.fnamemodify(csproj_path, ":t") -- just the filename, e.g. "MyApp.csproj"
  vim.notify("Building " .. name .. "...", vim.log.levels.INFO)

  vim.fn.jobstart(
    { "dotnet", "build", csproj_path, "--nologo", "-v:q" },
    {
      -- on_stderr collects build error output to show on failure
      stderr_buffered = true,
      on_stderr = function(_, data)
        if data and #data > 0 then
          -- Store for error notification (filter empty lines)
          vim.g._dap_build_errors = table.concat(
            vim.tbl_filter(function(l) return l ~= "" end, data), "\n"
          )
        end
      end,
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("Build succeeded ✓", vim.log.levels.INFO)
          on_done(true)
        else
          local errors = vim.g._dap_build_errors or "(no output)"
          vim.notify("Build FAILED:\n" .. errors, vim.log.levels.ERROR)
          vim.g._dap_build_errors = nil
          on_done(false)
        end
      end,
    }
  )
end

-- ─── 5. PARSE launchSettings.json ─────────────────────────────────────────────
-- Reads ALL "Project" profiles (skips IIS Express, Docker, etc.)
-- Returns a list of: { name, args (table), env (table), url (string|nil) }
local function get_launch_profiles(csproj_path)
  local dir = vim.fn.fnamemodify(csproj_path, ":h")
  local settings_path = dir .. "/Properties/launchSettings.json"

  if vim.fn.filereadable(settings_path) == 0 then return {} end

  local raw = table.concat(vim.fn.readfile(settings_path), "\n")
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or not data.profiles then return {} end

  local profiles = {}
  for name, profile in pairs(data.profiles) do
    -- commandName "Project" = runs with `dotnet run`, which is what we want
    -- Other values: "IISExpress", "Docker" — skip those
    if profile.commandName == "Project" then
      -- commandLineArgs is a single string like "--foo bar", split into a table
      local args = {}
      if profile.commandLineArgs and profile.commandLineArgs ~= "" then
        args = vim.split(profile.commandLineArgs, "%s+")
      end
      -- `dotnet run` automatically converts applicationUrl → ASPNETCORE_URLS.
      -- netcoredbg direct-launch does NOT, so we do it manually here.
      local env = vim.tbl_extend("force", {}, profile.environmentVariables or {})
      if profile.applicationUrl and profile.applicationUrl ~= "" then
        env["ASPNETCORE_URLS"] = profile.applicationUrl
      end
      table.insert(profiles, {
        name = name,
        args = args,
        env  = env,
        url  = profile.applicationUrl,
      })
    end
  end
  return profiles
end

-- ─── 6. MAIN ENTRY POINT ──────────────────────────────────────────────────────
-- pick_and_prepare(on_ready) is the function called from the DAP keymap.
-- It runs through the full flow async-style using callbacks, then calls:
--   on_ready(dll_path, args_table, env_table, cwd)
-- when everything is ready to hand off to dap.run().
M.pick_and_prepare = function(on_ready)
  -- Step A: find projects (from .sln or from current file's .csproj)
  local sln = find_solution()
  local projects = sln and parse_sln(sln) or {}

  if #projects == 0 then
    -- No solution found — fall back to current file's project
    local dotnet = require("configs.nvim-dap-dotnet")
    local root = dotnet.find_project_root_by_csproj(vim.fn.expand("%:p:h"))
    if root then
      projects = vim.fn.glob(root .. "/*.csproj", false, true)
    end
  end

  if #projects == 0 then
    vim.notify("[dotnet-debug] No .csproj found. Open a .cs file first.", vim.log.levels.ERROR)
    return
  end

  -- Step B: pick project (skip picker if there's only one)
  local function after_project_selected(csproj_path)
    local cwd = vim.fn.fnamemodify(csproj_path, ":h")
    -- Step C: build
    build_project(csproj_path, function(build_ok)
      if not build_ok then return end

      -- Step D: get DLL path
      local dll = get_dll_path(csproj_path)

      -- Step E: read launch profiles
      local profiles = get_launch_profiles(csproj_path)

      if #profiles == 0 then
        -- No launchSettings.json — just launch with no args or env
        on_ready(dll, {}, {}, cwd)
        return
      end

      if #profiles == 1 then
        -- Only one profile — use it without asking
        local p = profiles[1]
        on_ready(dll, p.args, p.env, cwd)
        return
      end

      -- Step F: pick profile
      vim.ui.select(profiles, {
        prompt = "Launch profile:",
        format_item = function(p)
          local label = p.name
          if p.url then label = label .. "  (" .. p.url .. ")" end
          return label
        end,
      }, function(profile)
        if not profile then
          vim.notify("[dotnet-debug] Cancelled", vim.log.levels.WARN)
          return
        end
        on_ready(dll, profile.args, profile.env, cwd)
      end)
    end)
  end

  if #projects == 1 then
    after_project_selected(projects[1])
  else
    vim.ui.select(projects, {
      prompt = "Select project to debug:",
      format_item = function(p)
        return vim.fn.fnamemodify(p, ":t:r") -- show just "MyApp" not the full path
      end,
    }, function(choice)
      if choice then after_project_selected(choice) end
    end)
  end
end

return M
