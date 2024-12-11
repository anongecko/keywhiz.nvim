-- lua/telescope/_extensions/keywhiz/integrations/nvchad.lua
local M = {}

-- Cache modules
local config = require("telescope._extensions.keywhiz.config")

-- State tracking
M.state = {
  mappings = {},
  ui_state = {},
}

-- Helper to get config paths
local function get_config_paths()
  local config_root = vim.fn.stdpath("config") .. "/lua"
  return {
    mappings = config_root .. "/mappings.lua",
    chadrc = config_root .. "/chadrc.lua",
  }
end

-- Parse user mappings from mappings.lua
local function parse_user_mappings()
  local ok, mappings = pcall(require, "mappings")
  if ok and mappings then
    -- Process the M.mappings table from mappings.lua
    for mode, mode_maps in pairs(mappings.mappings or {}) do
      for key, mapping_info in pairs(mode_maps) do
        local desc = type(mapping_info) == "table" and mapping_info[2] or mapping_info
        local cmd = type(mapping_info) == "table" and mapping_info[1] or mapping_info

        table.insert(M.state.mappings, {
          mode = mode,
          lhs = key,
          rhs = cmd,
          desc = desc,
          source = "user",
        })
      end
    end
  end
end

-- Get all keymaps
function M.get_keymaps()
  local keymaps = {}

  -- Add base NvChad mappings
  local base_ok, base_mappings = pcall(require, "nvchad.mappings")
  if base_ok then
    for mode, mode_maps in pairs(base_mappings) do
      for lhs, mapping_info in pairs(mode_maps) do
        table.insert(keymaps, {
          lhs = lhs,
          desc = type(mapping_info) == "table" and mapping_info[2] or mapping_info,
          mode = mode,
          source = "nvchad_core",
        })
      end
    end
  end

  -- Add user mappings
  vim.list_extend(keymaps, M.state.mappings)

  return keymaps
end

-- Setup function
function M.setup()
  -- Parse user mappings
  parse_user_mappings()

  -- Track UI state
  vim.api.nvim_create_autocmd("User", {
    pattern = { "NvChadThemeReload", "NvChadUiToggle" },
    callback = function()
      M.update_ui_state()
    end,
  })

  -- Setup highlights
  M.setup_highlights()
end

-- Update UI state
function M.update_ui_state()
  local ok, chadrc = pcall(require, "chadrc")
  M.state.ui_state = {
    theme = chadrc and chadrc.ui and chadrc.ui.theme or vim.g.nvchad_theme,
    transparency = chadrc and chadrc.ui and chadrc.ui.transparency or false,
    statusline = package.loaded["nvchad.ui.statusline"] ~= nil,
    tabufline = package.loaded["nvchad.ui.tabufline"] ~= nil,
  }
end

-- Setup highlights
function M.setup_highlights()
  local highlights = {
    KeymapSearchNvChadCore = { link = "String" },
    KeymapSearchNvChadUser = { link = "Function" },
  }

  for name, hl in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Get preview information
function M.get_preview_info(keymap)
  local lines = {
    "# NvChad Keymap Information",
    "",
    string.format("Source: %s", keymap.source),
  }

  if keymap.source == "user" then
    table.insert(lines, "")
    table.insert(lines, "User Mapping")
    table.insert(lines, string.format("Defined in: %s", get_config_paths().mappings))
  elseif keymap.source == "nvchad_core" then
    table.insert(lines, "")
    table.insert(lines, "NvChad Core Mapping")
  end

  -- Add UI state context if relevant
  if vim.tbl_contains({ "theme", "transparency", "statusline", "tabufline" }, keymap.category) then
    table.insert(lines, "")
    table.insert(lines, "UI State:")
    table.insert(lines, string.format("Current Theme: %s", M.state.ui_state.theme))
    table.insert(lines, string.format("Transparency: %s", M.state.ui_state.transparency))
  end

  return lines
end

-- Get entry information
function M.get_entry_info(keymap)
  local source_prefix = {
    nvchad_core = "Core",
    user = "User",
  }

  return string.format("NvChad [%s]", source_prefix[keymap.source])
end

-- Get commands for command palette
function M.get_commands()
  return {
    {
      name = "NvChadUpdate",
      desc = "Update NvChad",
      execute = function()
        vim.cmd("NvChadUpdate")
      end,
    },
    {
      name = "NvChadThemes",
      desc = "Browse themes",
      execute = function()
        vim.cmd("Telescope themes")
      end,
    },
  }
end

return M
