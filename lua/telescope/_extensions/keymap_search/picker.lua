-- lua/telescope/_extensions/keymap_search/picker.lua
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local themes = require("telescope.themes")

-- Cache commonly used modules
local config = require("telescope._extensions.keymap_search.config")
local favorites = require("telescope._extensions.keymap_search.favorites")
local history = require("telescope._extensions.keymap_search.history")
local keymap_actions = require("telescope._extensions.keymap_search.actions")
local utils = require("telescope._extensions.keymap_search.utils")

-- Integration modules
local integrations = {
  treesitter = require("telescope._extensions.keymap_search.integrations.treesitter"),
  lsp = require("telescope._extensions.keymap_search.integrations.lsp"),
  marks = require("telescope._extensions.keymap_search.integrations.marks"),
  buffer_window = require("telescope._extensions.keymap_search.integrations.buffer_window"),
  session = require("telescope._extensions.keymap_search.integrations.session"),
  terminal = require("telescope._extensions.keymap_search.integrations.terminal"),
}

local M = {}

-- Custom previewer for keymaps
local keymap_previewer = function(opts)
  return require("telescope.previewers").new_buffer_previewer({
    title = "Keymap Details",
    define_preview = function(self, entry)
      local bufnr = self.state.bufnr
      local keymap = entry.value
      local lines = {}

      -- Basic keymap information
      lines = vim.list_extend(lines, {
        "# Keymap Details",
        "",
        string.format("Mode:        %s", keymap.mode or "n"),
        string.format("Keys:        %s", keymap.lhs or ""),
        string.format("Description: %s", keymap.desc or ""),
        string.format("Source:      %s", utils.get_keymap_source(keymap)),
        "",
      })

      -- Integration-specific information
      for name, integration in pairs(integrations) do
        if integration.get_preview_info and config.is_integration_enabled(name) then
          local info = integration.get_preview_info(keymap)
          if info and #info > 0 then
            vim.list_extend(lines, {
              string.format("# %s Information", name:gsub("^%l", string.upper)),
              "",
            })
            vim.list_extend(lines, info)
            table.insert(lines, "")
          end
        end
      end

      -- Usage history
      local keymap_history = history.get_keymap_history(keymap)
      if #keymap_history > 0 then
        vim.list_extend(lines, {
          "# Usage History",
          "",
        })
        for i, hist in ipairs(keymap_history) do
          if i > 5 then
            break
          end
          table.insert(lines, string.format("• %s", os.date("%Y-%m-%d %H:%M", hist.timestamp)))
        end
      end

      -- Set buffer content
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    end,
  })
end

-- Create entry display
local create_entry_maker = function()
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 2 }, -- Favorite icon
      { width = 20 }, -- Keybinding
      { width = 3 }, -- Mode
      { remaining = true }, -- Description and integration info
    },
  })

  return function(entry)
    local keymap = entry
    local is_favorite = favorites.is_favorite(keymap)

    -- Collect information from enabled integrations
    local integration_info = {}
    for name, integration in pairs(integrations) do
      if integration.get_entry_info and config.is_integration_enabled(name) then
        local info = integration.get_entry_info(keymap)
        if info then
          table.insert(integration_info, info)
        end
      end
    end

    -- Format the display string
    local display = function(entry)
      local favorite_icon = is_favorite and "★" or " "
      local key_display = utils.format_key_combination(keymap.lhs)
      local mode_display = keymap.mode or "n"
      local desc_display = keymap.desc or ""

      -- Add integration information if available
      if #integration_info > 0 then
        desc_display = desc_display .. " [" .. table.concat(integration_info, " | ") .. "]"
      end

      return displayer({
        { favorite_icon, "KeywhizFavorite" },
        { key_display, "KeywhizKey" },
        { mode_display, "KeywhizMode" },
        { desc_display, "KeywhizDesc" },
      })
    end

    return {
      value = keymap,
      ordinal = string.format(
        "%s %s %s %s",
        keymap.lhs or "",
        keymap.desc or "",
        keymap.mode or "",
        table.concat(integration_info, " ")
      ),
      display = display,
    }
  end
end

-- Get keymaps from all sources
local function get_all_keymaps(opts)
  local keymaps = {}

  -- Get built-in keymaps
  for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "t", "c" }) do
    vim.list_extend(keymaps, vim.api.nvim_get_keymap(mode))
  end

  -- Get buffer-local keymaps
  local buf_maps = vim.api.nvim_buf_get_keymap(0, "")
  vim.list_extend(keymaps, buf_maps)

  -- Collect keymaps from enabled integrations
  for name, integration in pairs(integrations) do
    if integration.get_keymaps and config.is_integration_enabled(name) then
      local integration_maps = integration.get_keymaps()
      vim.list_extend(keymaps, integration_maps)
    end
  end

  return keymaps
end

-- Create the picker
function M.create_picker(opts)
  opts = opts or {}
  local cfg = config.get_config()

  -- Get keymaps and apply filters
  local all_keymaps = get_all_keymaps(opts)
  local filtered_keymaps = all_keymaps

  if opts.filter then
    filtered_keymaps = vim.tbl_filter(opts.filter, all_keymaps)
  end

  -- Create picker with theme
  local picker_opts = themes.get_dropdown(vim.tbl_deep_extend("force", {}, cfg.appearance.layout_config))

  pickers
    .new(picker_opts, {
      prompt_title = "Keymaps",
      finder = finders.new_table({
        results = filtered_keymaps,
        entry_maker = create_entry_maker(),
      }),
      sorter = conf.generic_sorter({}),
      previewer = cfg.features.enable_preview and keymap_previewer() or nil,
      attach_mappings = function(prompt_bufnr, map)
        -- Execute keymap
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            keymap_actions.execute_keymap(selection.value)
          end
        end)

        -- Additional mappings
        local additional_mappings = {
          ["<C-f>"] = function()
            local selection = action_state.get_selected_entry()
            if selection then
              keymap_actions.toggle_favorite(selection.value)
              -- Refresh display
              actions.close(prompt_bufnr)
              M.create_picker(opts)
            end
          end,
          ["<C-e>"] = function()
            local selection = action_state.get_selected_entry()
            if selection and cfg.features.enable_edit then
              actions.close(prompt_bufnr)
              keymap_actions.edit_keymap(selection.value)
            end
          end,
        }

        -- Add integration-specific mappings
        for name, integration in pairs(integrations) do
          if integration.get_mappings and config.is_integration_enabled(name) then
            vim.tbl_extend("force", additional_mappings, integration.get_mappings())
          end
        end

        -- Register all mappings
        for key, action in pairs(additional_mappings) do
          map("i", key, action)
        end

        return true
      end,
    })
    :find()
end

return M
