-- lua/telescope/_extensions/keywhiz/command_palette.lua
local M = {}
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local themes = require("telescope.themes")

-- Cache commonly used modules
local config = require("telescope._extensions.keywhiz.config")
local utils = require("telescope._extensions.keywhiz.utils")

-- Command types and their icons
M.command_types = {
  ex = { icon = ":", desc = "Ex command" },
  lua = { icon = "󰢱", desc = "Lua command" },
  keymap = { icon = "󰌌", desc = "Key mapping" },
  action = { icon = "󰘍", desc = "Action" },
  menu = { icon = "󰍉", desc = "Menu" },
}

-- Get all available commands
function M.get_commands()
  local commands = {}

  -- Ex commands
  for _, cmd in ipairs(vim.api.nvim_get_commands({})) do
    table.insert(commands, {
      type = "ex",
      name = cmd.name,
      desc = cmd.definition or "",
      execute = function()
        vim.cmd(cmd.name)
      end,
    })
  end

  -- Keymaps as commands
  local keymaps = require("telescope._extensions.keywhiz").get_all_keymaps()
  for _, map in ipairs(keymaps) do
    if map.desc then -- Only include documented mappings
      table.insert(commands, {
        type = "keymap",
        name = map.lhs,
        desc = map.desc,
        execute = function()
          require("telescope._extensions.keywhiz.actions").execute_keymap(map)
        end,
      })
    end
  end

  -- Integration-specific commands
  for name, integration in pairs({
    treesitter = require("telescope._extensions.keywhiz.integrations.treesitter"),
    lsp = require("telescope._extensions.keywhiz.integrations.lsp"),
    marks = require("telescope._extensions.keywhiz.integrations.marks"),
    buffer_window = require("telescope._extensions.keywhiz.integrations.buffer_window"),
    session = require("telescope._extensions.keywhiz.integrations.session"),
    terminal = require("telescope._extensions.keywhiz.integrations.terminal"),
  }) do
    if integration.get_commands and config.is_integration_enabled(name) then
      local integration_commands = integration.get_commands()
      for _, cmd in ipairs(integration_commands) do
        table.insert(commands, vim.tbl_extend("force", cmd, { type = "action" }))
      end
    end
  end

  return commands
end

-- Create the command palette picker
function M.show_palette(opts)
  opts = opts or {}
  local commands = M.get_commands()

  -- Create entry display
  local displayer = require("telescope.pickers.entry_display").create({
    separator = " ",
    items = {
      { width = 2 }, -- Type icon
      { width = 30 }, -- Command name
      { remaining = true }, -- Description
    },
  })

  local make_display = function(entry)
    local type_info = M.command_types[entry.type]
    return displayer({
      { type_info.icon, "KeywhizCommand" .. entry.type:gsub("^%l", string.upper) },
      { entry.name, "KeywhizCommandName" },
      { entry.desc, "KeywhizCommandDesc" },
    })
  end

  -- Create picker
  local picker_opts = themes.get_dropdown(vim.tbl_deep_extend("force", {
    layout_config = {
      width = 0.8,
      height = 0.6,
    },
  }, opts))

  pickers
    .new(picker_opts, {
      prompt_title = "Command Palette",
      finder = finders.new_table({
        results = commands,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = string.format("%s %s %s", entry.type, entry.name, entry.desc),
          }
        end,
      }),
      sorter = require("telescope.config").values.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value.execute then
            selection.value.execute()
          end
        end)
        return true
      end,
    })
    :find()
end

-- Register command palette commands
function M.setup()
  vim.api.nvim_create_user_command("KeymapsPalette", function()
    M.show_palette()
  end, {
    desc = "Show command palette",
  })
end

return M
