local M = {}

-- Cache our modules
local integrations = {
  treesitter = require("telescope._extensions.keywhiz.integrations.treesitter"),
  marks = require("telescope._extensions.keywhiz.integrations.marks"),
  buffer_window = require("telescope._extensions.keywhiz.integrations.buffer_window"),
  session = require("telescope._extensions.keywhiz.integrations.session"),
  terminal = require("telescope._extensions.keywhiz.integrations.terminal"),
}

-- Initial setup function
function M.setup(opts)
  -- Setup base configuration
  require("telescope._extensions.keywhiz.config").setup(opts)

  -- Initialize integrations
  for name, integration in pairs(integrations) do
    if opts.integrations[name] ~= false then -- Enable by default unless explicitly disabled
      integration.setup()
    end
  end

  -- Create necessary cache directories
  local cache_dir = vim.fn.stdpath("cache") .. "/keymap_search"
  vim.fn.mkdir(cache_dir, "p")

  -- Set up core components
  require("telescope._extensions.keywhiz.history").setup(cache_dir)
  require("telescope._extensions.keywhiz.favorites").setup(cache_dir)
end

-- Get all available keymaps with context
function M.get_all_keymaps()
  local keymaps = {}

  -- Get basic vim keymaps
  for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "t", "c" }) do
    local mode_maps = vim.api.nvim_get_keymap(mode)
    vim.list_extend(keymaps, mode_maps)
  end

  -- Add TreeSitter context-aware keymaps
  if integrations.treesitter then
    vim.list_extend(keymaps, integrations.treesitter.get_context_keymaps())
  end

  -- Add marks and registers
  if integrations.marks then
    local marks_keymaps = integrations.marks.get_marks()
    local register_keymaps = integrations.marks.get_registers()
    vim.list_extend(keymaps, marks_keymaps)
    vim.list_extend(keymaps, register_keymaps)
  end

  -- Add window/buffer management keymaps
  if integrations.buffer_window then
    vim.list_extend(keymaps, integrations.buffer_window.update_window_keymaps())
  end

  -- Add terminal keymaps
  if integrations.terminal then
    vim.list_extend(keymaps, integrations.terminal.get_terminal_keymaps())
  end

  return keymaps
end

-- Create the telescope picker
function M.show_keymaps(opts)
  opts = opts or {}

  -- Get all keymaps
  local all_keymaps = M.get_all_keymaps()

  -- Apply filters based on options
  local filtered_keymaps = all_keymaps
  if opts.filter then
    filtered_keymaps = vim.tbl_filter(function(keymap)
      return opts.filter(keymap)
    end, all_keymaps)
  end

  -- Create and show the picker
  require("telescope._extensions.keywhiz.picker").create_picker(filtered_keymaps, opts)
end

-- Register extension with telescope
function M.register_extension()
  return require("telescope").register_extension({
    exports = {
      keywhiz = M.show_keymaps,
      marks = function()
        M.show_keymaps({ category = "marks" })
      end,
      registers = function()
        M.show_keymaps({ category = "registers" })
      end,
      windows = function()
        M.show_keymaps({ category = "windows" })
      end,
      terminals = function()
        M.show_keymaps({ category = "terminals" })
      end,
      sessions = function()
        M.show_keymaps({ category = "sessions" })
      end,
    },
    setup = M.setup,
  })
end

-- Register commands
function M.create_commands()
  local commands = {
    Keymaps = { M.show_keymaps, {} },
    KeymapsMarks = { M.show_keymaps, { category = "marks" } },
    KeymapsRegisters = { M.show_keymaps, { category = "registers" } },
    KeymapsWindows = { M.show_keymaps, { category = "windows" } },
    KeymapsTerminals = { M.show_keymaps, { category = "terminals" } },
    KeymapsSessions = { M.show_keymaps, { category = "sessions" } },
  }

  for command_name, command_data in pairs(commands) do
    vim.api.nvim_create_user_command(command_name, function(opts)
      command_data[1](command_data[2])
    end, {})
  end
end

return M
