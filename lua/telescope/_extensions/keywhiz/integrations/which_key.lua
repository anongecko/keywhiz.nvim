-- lua/telescope/_extensions/keywhiz/integrations/which_key.lua
local M = {}

-- Cache commonly used modules
local config = require("telescope._extensions.keywhiz.config")
local utils = require("telescope._extensions.keywhiz.utils")

-- Cache for which-key registrations
M.which_key_cache = {
  groups = {},
  mappings = {},
  prefixes = {},
  tree = {},
}

-- Helper to build key tree
local function build_key_tree()
  M.which_key_cache.tree = {}

  for prefix, group in pairs(M.which_key_cache.groups) do
    local current = M.which_key_cache.tree
    local parts = vim.split(prefix, "")

    for _, part in ipairs(parts) do
      current[part] = current[part] or {}
      current = current[part]
    end

    current._group = group
  end

  for lhs, mapping in pairs(M.which_key_cache.mappings) do
    local current = M.which_key_cache.tree
    local parts = vim.split(lhs, "")

    for _, part in ipairs(parts) do
      current[part] = current[part] or {}
      current = current[part]
    end

    current._mapping = mapping
  end
end

-- Setup which-key integration
function M.setup()
  local ok, which_key = pcall(require, "which-key")
  if not ok then
    return
  end

  -- Override which-key registration to capture mappings
  local original_register = which_key.register
  which_key.register = function(mappings, opts)
    opts = opts or {}

    -- Process mappings
    for key_prefix, mapping_info in pairs(mappings) do
      if type(mapping_info) == "table" then
        if mapping_info.name then
          -- This is a group
          M.which_key_cache.groups[key_prefix] = {
            name = mapping_info.name,
            prefix = key_prefix,
            mode = opts.mode or "n",
            buffer = opts.buffer,
          }
        else
          -- These are mappings
          for k, v in pairs(mapping_info) do
            local full_key = key_prefix .. k
            M.which_key_cache.mappings[full_key] = {
              lhs = full_key,
              desc = type(v) == "table" and v[2] or v,
              mode = opts.mode or "n",
              buffer = opts.buffer,
              group = key_prefix,
            }
          end
        end
      end
    end

    -- Rebuild tree
    build_key_tree()

    -- Call original registration
    return original_register(mappings, opts)
  end

  -- Add keywhiz group
  which_key.register({
    ["<leader>k"] = {
      name = "Keymap Search",
      s = { "<cmd>Telescope keymap_search<cr>", "Search Keymaps" },
      f = { "<cmd>Telescope keymap_search category=9<cr>", "Favorites" },
      h = { "<cmd>Telescope keymap_search category=8<cr>", "History" },
      c = { "<cmd>Telescope keymap_search conflicts<cr>", "Check Conflicts" },
      g = { "<cmd>Telescope keymap_search groups<cr>", "Key Groups" },
      p = { "<cmd>KeymapsPalette<cr>", "Command Palette" },
    },
  })

  -- Track mode changes for context
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*",
    callback = function()
      local mode = vim.api.nvim_get_mode().mode
      M.update_mode_context(mode)
    end,
  })
end

-- Get group information for a keymap
function M.get_group_info(keymap)
  if not keymap.lhs then
    return nil
  end

  local current = M.which_key_cache.tree
  local parts = vim.split(keymap.lhs, "")
  local groups = {}
  local current_prefix = ""

  for _, part in ipairs(parts) do
    current_prefix = current_prefix .. part
    if current[part] and current[part]._group then
      table.insert(groups, {
        name = current[part]._group.name,
        prefix = current_prefix,
        level = #groups + 1,
      })
    end
    current = current[part] or {}
  end

  return groups
end

-- Get preview information for which-key groups
function M.get_preview_info(keymap)
  local groups = M.get_group_info(keymap)
  if not groups or #groups == 0 then
    return {}
  end

  local lines = {
    "# Which-Key Groups",
    "",
  }

  for _, group in ipairs(groups) do
    table.insert(lines, string.format("%s%s (%s)", string.rep("  ", group.level - 1), group.name, group.prefix))
  end

  -- Add available subcommands in the group
  local current_group = groups[#groups]
  if current_group then
    table.insert(lines, "")
    table.insert(lines, "Available commands in group:")
    table.insert(lines, "")

    for lhs, mapping in pairs(M.which_key_cache.mappings) do
      if vim.startswith(lhs, current_group.prefix) then
        table.insert(lines, string.format("  %s → %s", lhs:sub(#current_group.prefix + 1), mapping.desc or ""))
      end
    end
  end

  return lines
end

-- Get entry information for the picker
function M.get_entry_info(keymap)
  local groups = M.get_group_info(keymap)
  if not groups or #groups == 0 then
    return nil
  end

  return string.format("Group: %s", groups[#groups].name)
end

-- Show which-key style popup for a keymap
function M.show_popup(keymap)
  local ok, which_key = pcall(require, "which-key")
  if not ok then
    return
  end

  local groups = M.get_group_info(keymap)
  if not groups or #groups == 0 then
    return
  end

  local current_group = groups[#groups]
  local mappings = {}

  for lhs, mapping in pairs(M.which_key_cache.mappings) do
    if vim.startswith(lhs, current_group.prefix) then
      local suffix = lhs:sub(#current_group.prefix + 1)
      mappings[suffix] = { nil, mapping.desc }
    end
  end

  which_key.show(current_group.prefix, {
    mode = keymap.mode,
    auto = true,
    mappings = mappings,
  })
end

-- Update context based on mode
function M.update_mode_context(mode)
  local keymaps = {}

  for lhs, mapping in pairs(M.which_key_cache.mappings) do
    if mapping.mode == mode then
      table.insert(keymaps, mapping)
    end
  end

  -- Register mode-specific keymaps with which-key
  local ok, which_key = pcall(require, "which-key")
  if ok then
    which_key.register(keymaps, { mode = mode })
  end
end

-- Get all which-key groups
function M.get_groups()
  return vim.tbl_values(M.which_key_cache.groups)
end

-- Get mappings for a specific group
function M.get_group_mappings(group_prefix)
  local mappings = {}

  for lhs, mapping in pairs(M.which_key_cache.mappings) do
    if vim.startswith(lhs, group_prefix) then
      table.insert(mappings, mapping)
    end
  end

  return mappings
end

-- Register a new group dynamically
function M.register_group(prefix, name, mappings)
  local ok, which_key = pcall(require, "which-key")
  if not ok then
    return
  end

  local group_mappings = {
    [prefix] = {
      name = name,
    },
  }

  -- Add provided mappings
  if mappings then
    for k, v in pairs(mappings) do
      group_mappings[prefix .. k] = v
    end
  end

  which_key.register(group_mappings)
end

-- Export group to a format compatible with keymap-search
function M.export_group(group_prefix)
  local keymaps = {}

  -- Add group itself
  local group = M.which_key_cache.groups[group_prefix]
  if group then
    table.insert(keymaps, {
      lhs = group_prefix,
      desc = group.name,
      mode = group.mode,
      is_group = true,
    })
  end

  -- Add all mappings in the group
  local group_mappings = M.get_group_mappings(group_prefix)
  vim.list_extend(keymaps, group_mappings)

  return keymaps
end

-- Get command palette entries for which-key groups
function M.get_commands()
  local commands = {}

  -- Add group navigation commands
  for prefix, group in pairs(M.which_key_cache.groups) do
    table.insert(commands, {
      name = "Group: " .. group.name,
      desc = "Navigate to key group " .. prefix,
      execute = function()
        local ok, which_key = pcall(require, "which-key")
        if ok then
          which_key.show(prefix)
        end
      end,
    })
  end

  return commands
end

return M
