-- highlights.lua: Manages highlight groups and colors for keywhiz.nvim
local M = {}

-- Cache the config module
local config = require("telescope._extensions.keymap_search.config")

-- Define base colors (using Catppuccin Mocha as default)
M.colors = {
  -- Base colors
  rosewater = "#f5e0dc",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  mauve = "#cba6f7",
  red = "#f38ba8",
  maroon = "#eba0ac",
  peach = "#fab387",
  yellow = "#f9e2af",
  green = "#a6e3a1",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  blue = "#89b4fa",
  lavender = "#b4befe",
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  overlay2 = "#9399b2",
  surface2 = "#585b70",
}

-- Define highlight groups with their default values
M.groups = {
  -- Key type highlights
  KeywhizNormal = { fg = M.colors.text },
  KeywhizLeader = { fg = M.colors.blue, bold = true },
  KeywhizCtrl = { fg = M.colors.red },
  KeywhizAlt = { fg = M.colors.green },
  KeywhizShift = { fg = M.colors.peach },
  KeywhizSpecial = { fg = M.colors.mauve },
  KeywhizFunction = { fg = M.colors.yellow },
  KeywhizLSP = { fg = M.colors.teal },
  KeywhizRegister = { fg = M.colors.flamingo },
  KeywhizFold = { fg = M.colors.lavender },

  -- UI element highlights
  KeywhizBorder = { fg = M.colors.surface2 },
  KeywhizTitle = { fg = M.colors.blue, bold = true },
  KeywhizCategory = { fg = M.colors.mauve, bold = true },
  KeywhizSource = { fg = M.colors.subtext1 },
  KeywhizContext = { fg = M.colors.overlay2, italic = true },

  -- Special highlights
  KeywhizFavorite = { fg = M.colors.yellow, bold = true },
  KeywhizHistory = { fg = M.colors.sapphire },
  KeywhizModified = { fg = M.colors.peach, italic = true },
  KeywhizDeprecated = { fg = M.colors.red, strikethrough = true },

  -- Mode highlights
  KeywhizModeNormal = { fg = M.colors.blue },
  KeywhizModeInsert = { fg = M.colors.green },
  KeywhizModeVisual = { fg = M.colors.mauve },
  KeywhizModeCommand = { fg = M.colors.yellow },
  KeywhizModeTerminal = { fg = M.colors.teal },

  -- Category highlights
  KeywhizCategoryMovement = { fg = M.colors.blue },
  KeywhizCategoryEdit = { fg = M.colors.green },
  KeywhizCategoryLSP = { fg = M.colors.teal },
  KeywhizCategoryWindow = { fg = M.colors.mauve },
  KeywhizCategoryFile = { fg = M.colors.peach },
  KeywhizCategorySearch = { fg = M.colors.yellow },
  KeywhizCategoryGit = { fg = M.colors.red },
  KeywhizCategoryMisc = { fg = M.colors.subtext1 },
}

-- Function to set up all highlights
function M.setup()
  -- Get user config
  local user_config = config.get_config()

  -- Merge user-defined colors with defaults
  if user_config.colors then
    M.colors = vim.tbl_deep_extend("force", M.colors, user_config.colors)
  end

  -- Create highlight groups
  for group_name, group_settings in pairs(M.groups) do
    -- Allow user override of specific highlight groups
    if user_config.highlights and user_config.highlights[group_name] then
      group_settings = vim.tbl_deep_extend("force", group_settings, user_config.highlights[group_name])
    end

    vim.api.nvim_set_hl(0, group_name, group_settings)
  end

  -- Set up linked groups for compatibility
  local links = {
    -- Maintain compatibility with older versions
    KeymapSearchNormal = "KeywhizNormal",
    KeymapSearchLeader = "KeywhizLeader",
    KeymapSearchCtrl = "KeywhizCtrl",
    KeymapSearchAlt = "KeywhizAlt",
    KeymapSearchShift = "KeywhizShift",

    -- Link to built-in groups for better integration
    KeywhizFloat = "NormalFloat",
    KeywhizSelection = "Visual",
    KeywhizCursor = "Cursor",
    KeywhizMatch = "TelescopeMatching",
  }

  -- Create linked groups
  for from, to in pairs(links) do
    vim.api.nvim_set_hl(0, from, { link = to })
  end
end

-- Function to update a specific highlight group
function M.update_highlight(group, settings)
  if M.groups[group] then
    M.groups[group] = vim.tbl_deep_extend("force", M.groups[group], settings)
    vim.api.nvim_set_hl(0, group, M.groups[group])
  end
end

-- Function to get current highlight settings
function M.get_highlight(group)
  return M.groups[group]
end

-- Function to reset highlights to defaults
function M.reset()
  M.setup()
end

-- Function to update color scheme
function M.update_colors(colors)
  M.colors = vim.tbl_deep_extend("force", M.colors, colors)
  M.setup()
end

-- Function to get all highlight groups
function M.get_groups()
  return vim.deepcopy(M.groups)
end

-- Auto-setup on module load if config is available
if config.is_configured() then
  M.setup()
end

return M
