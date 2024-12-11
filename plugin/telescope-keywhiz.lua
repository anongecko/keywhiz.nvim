-- Guard against multiple loads and Neovim version compatibility
if vim.g.loaded_telescope_keymap_search == 1 then
  return
end

if vim.fn.has("nvim-0.9.0") == 0 then
  vim.api.nvim_err_writeln("telescope-keywhiz requires Neovim >= 0.9.0")
  return
end

vim.g.loaded_telescope_keymap_search = 1

-- Plugin setup helper functions
local function ensure_dependencies()
  -- Check core dependencies
  local has_telescope, _ = pcall(require, "telescope")
  if not has_telescope then
    vim.api.nvim_err_writeln("telescope-keywhiz requires telescope.nvim")
    return false
  end

  -- Log optional integration availability
  local integrations = {
    which_key = pcall(require, "which-key"),
    nvchad = vim.g.nvchad_theme ~= nil,
    treesitter = pcall(require, "nvim-treesitter"),
  }

  return true, integrations
end

local function create_commands()
  -- Main keymap search command
  vim.api.nvim_create_user_command("Keymaps", function(opts)
    require("telescope").extensions.keymap_search.show(opts.args)
  end, {
    nargs = "?",
    complete = function(_, line)
      return require("telescope._extensions.keywhiz.config").get_categories()
    end,
    desc = "Search and manage keymaps",
  })

  -- Category-specific commands
  local categories = {
    Movement = "2",
    Editing = "3",
    LSP = "4",
    Windows = "5",
    Files = "6",
    Plugins = "7",
    History = "8",
    Favorites = "9",
  }

  for category, key in pairs(categories) do
    vim.api.nvim_create_user_command("Keymaps" .. category, function()
      require("telescope").extensions.keymap_search.show(key)
    end, {
      desc = "Search " .. category .. " keymaps",
    })
  end

  -- Additional functionality commands
  vim.api.nvim_create_user_command("KeymapsPalette", function()
    require("telescope._extensions.keywhiz.command_palette").show()
  end, {
    desc = "Show command palette",
  })

  vim.api.nvim_create_user_command("KeymapsConflicts", function()
    require("telescope._extensions.keywhiz.conflicts").show_conflicts()
  end, {
    desc = "Show keymap conflicts",
  })
end

local function create_highlights()
  local highlights = {
    -- Base highlights
    KeymapSearchNormal = { fg = "#cdd6f4" },
    KeymapSearchLeader = { fg = "#89b4fa", bold = true },
    KeymapSearchCtrl = { fg = "#f38ba8" },
    KeymapSearchAlt = { fg = "#a6e3a1" },
    KeymapSearchShift = { fg = "#fab387" },
    KeymapSearchCategory = { fg = "#cba6f7", bold = true },
    KeymapSearchTag = { fg = "#94e2d5" },
    KeymapSearchFavorite = { fg = "#f9e2af", bold = true },

    -- Integration-specific highlights
    KeymapSearchWhichKey = { fg = "#89b4fa", italic = true },
    KeymapSearchNvChadCore = { fg = "#a6e3a1" },
    KeymapSearchNvChadUser = { fg = "#f38ba8" },
    KeymapSearchTreeSitter = { fg = "#f9e2af", italic = true },

    -- Special states
    KeymapSearchConflict = { fg = "#f38ba8", bold = true },
    KeymapSearchDeprecated = { fg = "#6c7086", strikethrough = true },
    KeymapSearchModified = { fg = "#f9e2af", italic = true },
  }

  for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
  end
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("TelescopeKeymapSearch", { clear = true })

  -- Save history and favorites when leaving Neovim
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      local history = require("telescope._extensions.keywhiz.history")
      local favorites = require("telescope._extensions.keywhiz.favorites")
      history.save_entries(history.get_entries())
      favorites.save_entries(favorites.get_entries())
    end,
  })

  -- Update keymaps when new plugins are loaded
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyLoad",
    callback = function()
      vim.schedule(function()
        require("telescope._extensions.keywhiz.utils").refresh_keymap_cache()
      end)
    end,
  })

  -- Track theme changes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      require("telescope._extensions.keywhiz.themes").update_theme()
    end,
  })

  -- Integration-specific autocmds
  if vim.g.nvchad_theme then
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = { "NvChadThemeReload", "NvChadUiToggle" },
      callback = function()
        require("telescope._extensions.keywhiz.integrations.nvchad").update_ui_state()
      end,
    })
  end
end

local function setup_integrations(available_integrations)
  local integrations = {
    which_key = "which_key",
    nvchad = "nvchad",
    treesitter = "treesitter",
  }

  for name, module in pairs(integrations) do
    if available_integrations[name] then
      local ok, integration = pcall(require, "telescope._extensions.keywhiz.integrations." .. module)
      if ok and integration.setup then
        integration.setup()
      end
    end
  end
end

local function setup_telescope_extension()
  local telescope = require("telescope")
  local themes = require("telescope._extensions.keywhiz.themes")

  telescope.setup({
    extensions = {
      keymap_search = require("telescope._extensions.keywhiz.config").defaults,
    },
  })

  -- Register pickers
  telescope.register_extension({
    exports = {
      -- Main keymap search
      keymap_search = require("telescope._extensions.keywhiz.picker").create_picker,

      -- Additional pickers
      conflicts = require("telescope._extensions.keywhiz.conflicts").show_conflicts,
      palette = require("telescope._extensions.keywhiz.command_palette").show_palette,

      -- Theme support
      themes = themes.show_themes,
    },
    setup = function(ext_config)
      -- Allow extension configuration
      require("telescope._extensions.keywhiz.config").setup(ext_config)
    end,
  })
end

-- Plugin initialization
local function init()
  local has_deps, available_integrations = ensure_dependencies()
  if not has_deps then
    return
  end

  -- Initialize cache directory
  local cache_dir = vim.fn.stdpath("cache") .. "/telescope-keywhiz"
  vim.fn.mkdir(cache_dir, "p")

  -- Setup core components
  require("telescope._extensions.keywhiz.history").setup(cache_dir)
  require("telescope._extensions.keywhiz.favorites").setup(cache_dir)
  require("telescope._extensions.keywhiz.themes").setup()

  -- Setup all available integrations
  setup_integrations(available_integrations)

  -- Create UI elements
  create_highlights()
  create_commands()
  create_autocmds()

  -- Initialize telescope extension
  setup_telescope_extension()
end

-- Schedule initialization to ensure proper loading order
vim.schedule(init)

-- Expose plugin API for advanced usage
_G.TelescopeKeymapSearch = {
  -- Core functionality
  show = function(category)
    require("telescope").extensions.keymap_search.show(category)
  end,

  -- Category management
  add_category = function(name, patterns)
    local categories = require("telescope._extensions.keywhiz.categories")
    categories.add_custom_category(name, patterns)
  end,

  -- Keymap registration
  register_keymap = function(mode, lhs, desc, category)
    local utils = require("telescope._extensions.keywhiz.utils")
    utils.register_manual_keymap(mode, lhs, desc, category)
  end,

  -- Theme management
  set_theme = function(theme_name)
    require("telescope._extensions.keywhiz.themes").set_theme(theme_name)
  end,

  -- Integration utilities
  get_integration = function(name)
    return require("telescope._extensions.keywhiz.integrations." .. name)
  end,

  -- Command palette
  show_palette = function()
    require("telescope._extensions.keywhiz.command_palette").show()
  end,

  -- Conflict checking
  check_conflicts = function()
    return require("telescope._extensions.keywhiz.conflicts").detect_conflicts()
  end,
}

-- Return API for programmatic usage
return _G.TelescopeKeymapSearch
