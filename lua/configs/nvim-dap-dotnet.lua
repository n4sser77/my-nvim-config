local M = {}

function M.find_project_root_by_csproj(start_path)
  local Path = require("plenary.path")
  local path = Path:new(start_path)

  while true do
    local csproj_files = vim.fn.glob(path:absolute() .. "/*.csproj", false, true)
    if #csproj_files > 0 then
      return path:absolute()
    end

    local parent = path:parent()
    if parent:absolute() == path:absolute() then
      return nil
    end

    path = parent
  end
end

function M.get_highest_net_folder(bin_debug_path)
  local dirs = vim.fn.glob(bin_debug_path .. "/net*", false, true)

  if dirs == 0 or dirs == nil then
    error("No netX.Y folders found in " .. bin_debug_path)
  end

  table.sort(dirs, function(a, b)
    local ver_a = tonumber(a:match("net(%d+)%.%d+"))
    local ver_b = tonumber(b:match("net(%d+)%.%d+"))
    if not ver_a then return false end
    if not ver_b then return true end
    return ver_a > ver_b
  end)

  return dirs[1]
end

function M.build_dll_path()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ":p:h")

  local project_root = M.find_project_root_by_csproj(current_dir)
  if not project_root then
    error("Could not find project root (no .csproj found)")
  end

  local csproj_files = vim.fn.glob(project_root .. "/*.csproj", false, true)
  if #csproj_files == 0 then
    error("No .csproj file found in project root")
  end

  local project_name = vim.fn.fnamemodify(csproj_files[1], ":t:r")
  local bin_debug_path = project_root .. "/bin/Debug"

  local highest_net_folder = M.get_highest_net_folder(bin_debug_path)
  local dll_path = highest_net_folder .. "/" .. project_name .. ".dll"

  print("Launching: " .. dll_path)
  return dll_path
end

function M.get_launch_profiles(project_root)
  local root = project_root or M.find_project_root_by_csproj(vim.fn.getcwd())
  if not root then
    return {}
  end

  local launch_settings_path = root .. "/Properties/launchSettings.json"
  if vim.fn.filereadable(launch_settings_path) == 0 then
    return {}
  end

  local content = vim.fn.readfile(launch_settings_path)
  local json_str = table.concat(content, "\n")
  local ok, data = pcall(vim.json.decode, json_str)
  if not ok or not data.profiles then
    return {}
  end

  local profiles = {}
  for name, profile in pairs(data.profiles) do
    if profile.applicationUrl then
      table.insert(profiles, {
        name = name,
        url = profile.applicationUrl,
        env = profile.environmentVariables or {},
      })
    end
  end

  return profiles
end

return M
