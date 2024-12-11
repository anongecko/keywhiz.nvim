local M = {}

M.defaults = {
  -- UI Configuration
  appearance = {
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.95,
      height = 0.8,
      preview_width = 0.5,
    },
    color_scheme = {
      leader = "#89b4fa", -- Leader keys
      ctrl = "#f38ba8", -- Control combinations
      alt = "#a6e3a1", -- Alt combinations
      shift = "#fab387", -- Shift combinations
      normal = "#cdd6f4", -- Regular keys
    },
  },

  integrations = {
    treesitter = {
      enabled = true,
      show_context = true,
      context_depth = 3,
      show_scope = true,
    },
    marks = {
      enabled = true,
      show_content_preview = true,
      max_register_preview = 50,
      register_preview_lines = 5,
    },
    buffer_window = {
      enabled = true,
      show_layout_preview = true,
      layout_in_preview = true,
      show_diagnostics = true,
    },
    session = {
      enabled = true,
      auto_save = true,
      save_interval = 300,
      session_dir = vim.fn.stdpath("data") .. "/keywhiz/sessions",
    },
    terminal = {
      enabled = true,
      float_by_default = true,
      float_size = { width = 0.8, height = 0.8 },
      shell = vim.o.shell,
      position = "center", -- center, bottom, right
    },
  },

  -- Categories for organization
  categories = {
    { key = "1", name = "All", filter = nil },
    { key = "2", name = "Movement", filter = "category:movement" },
    { key = "3", name = "Editing", filter = "category:edit" },
    { key = "4", name = "LSP", filter = "category:lsp" },
    { key = "5", name = "Windows", filter = "category:window" },
    { key = "6", name = "Files", filter = "category:file" },
    { key = "7", name = "Plugins", filter = "category:plugin" },
    { key = "8", name = "History", special = "history" },
    { key = "9", name = "Favorites", special = "favorites" },
    { key = "m", name = "Marks", filter = "category:marks" },
    { key = "r", name = "Registers", filter = "category:registers" },
    { key = "w", name = "Windows", filter = "category:windows" },
    { key = "t", name = "Terminals", filter = "category:terminals" },
    { key = "s", name = "Sessions", filter = "category:sessions" },
  },

  -- Feature toggles
  features = {
    show_context = true, -- Show context info
    show_source = true, -- Show source of keymaps
    show_alternatives = true, -- Show alternative keymaps
    enable_edit = true, -- Allow editing keymaps
    enable_preview = true, -- Show preview window
  },

  -- History settings
  history = {
    max_entries = 100,
    save_to_disk = true,
  },

  -- Favorites settings
  favorites = {
    max_entries = 50,
    save_to_disk = true,
  },

  -- Icons configuration
  icons = {
    movement = " ",
    edit = "󰤌 ",
    lsp = " ",
    window = "󱂬 ",
    file = " ",
    search = " ",
    fold = " ",
    plugin = "󰏗 ",
    misc = " ",
    git = " ",
    custom = "󰌌 ",
    marks = "󰓾 ",
    registers = "󰘎 ",
    windows = "󱂬 ",
    terminals = " ",
    sessions = "󱉽 ",
  },

  -- Key mappings within the picker
  mappings = {
    i = {
      execute = "<CR>",
      toggle_favorite = "<C-f>",
      edit_keymap = "<C-e>",
      preview_scroll_up = "<C-u>",
      preview_scroll_down = "<C-d>",
      toggle_preview = "<C-p>",
      create_terminal = "<C-t>",
      toggle_mark = "<C-m>",
      yank_register = "<C-y>",
      save_session = "<C-s>",
      load_session = "<C-l>",
    },
  },
}

local config = M.defaults

function M.get_config()
  return config
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return config
end

function M.get_categories()
  return vim.tbl_map(function(cat)
    return cat.name
  end, config.categories)
end

-- Helper function to get icon
function M.get_icon(category)
  return config.icons[category] or config.icons.misc
end

-- Helper function to get color
function M.get_color(key_type)
  return config.appearance.color_scheme[key_type] or config.appearance.color_scheme.normal
end

-- Add new helper functions for integrations
function M.get_integration_config(name)
  return config.integrations[name]
end

function M.is_integration_enabled(name)
  local integration = config.integrations[name]
  return integration and integration.enabled
end

-- Add function to validate integration configuration
function M.validate_integration_config(name, provided_config)
  local valid_options = {
    treesitter = { "show_context", "context_depth", "show_scope" },
    marks = { "show_content_preview", "max_register_preview", "register_preview_lines" },
    buffer_window = { "show_layout_preview", "layout_in_preview", "show_diagnostics" },
    session = { "auto_save", "save_interval", "session_dir" },
    terminal = { "float_by_default", "float_size", "shell", "position" },
  }

  if not valid_options[name] then
    return false, "Invalid integration name: " .. name
  end

  for key, _ in pairs(provided_config) do
    if not vim.tbl_contains(valid_options[name], key) then
      return false, "Invalid option for " .. name .. ": " .. key
    end
  end

  return true, nil
end

return M
