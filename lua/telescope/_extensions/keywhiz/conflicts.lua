-- lua/telescope/_extensions/keywhiz/conflicts.lua
local M = {}
local config = require("telescope._extensions.keywhiz.config")

-- Enhanced conflict types
M.conflict_types = {
  direct = { severity = "error", icon = "󰚌 ", desc = "Direct key conflict" },
  prefix = { severity = "warning", icon = "󰀦 ", desc = "Key prefix conflict" },
  mode = { severity = "info", icon = "󰯊 ", desc = "Mode overlap" },
  inactive = { severity = "hint", icon = "󰘥 ", desc = "Inactive mapping" },
}

-- Cache for quicker lookups
local keymap_cache = {}
local prefix_tree = {}

-- Build prefix tree for efficient conflict detection
local function build_prefix_tree(keymaps)
  prefix_tree = {}
  for _, map in ipairs(keymaps) do
    local current = prefix_tree
    local keys = vim.split(map.lhs, "")
    for _, key in ipairs(keys) do
      current[key] = current[key] or {}
      current = current[key]
    end
    current._mapping = map
  end
end

-- Check for conflicts in prefix tree
local function check_prefix_conflicts(tree, prefix, conflicts)
  for key, subtree in pairs(tree) do
    if key ~= "_mapping" then
      local current_prefix = prefix .. key
      if subtree._mapping then
        -- Check for prefix conflicts
        for _, other_map in pairs(keymap_cache) do
          if other_map.lhs:find("^" .. vim.pesc(current_prefix)) then
            table.insert(conflicts, {
              type = "prefix",
              first = subtree._mapping,
              second = other_map,
              prefix = current_prefix,
            })
          end
        end
      end
      check_prefix_conflicts(subtree, current_prefix, conflicts)
    end
  end
end

function M.detect_conflicts()
  local conflicts = {}
  keymap_cache = {}

  -- Get all keymaps
  for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "t", "c" }) do
    local maps = vim.api.nvim_get_keymap(mode)
    for _, map in ipairs(maps) do
      local key = mode .. map.lhs
      if keymap_cache[key] then
        -- Direct conflict
        table.insert(conflicts, {
          type = "direct",
          first = keymap_cache[key],
          second = map,
          mode = mode,
        })
      end
      keymap_cache[key] = map
    end
  end

  -- Build and check prefix tree
  build_prefix_tree(vim.tbl_values(keymap_cache))
  check_prefix_conflicts(prefix_tree, "", conflicts)

  return conflicts
end

-- Format conflict for display
function M.format_conflict(conflict)
  local type_info = M.conflict_types[conflict.type]
  local desc = string.format(
    "%s %s: %s conflicts with %s",
    type_info.icon,
    type_info.desc,
    conflict.first.lhs,
    conflict.second.lhs
  )

  if conflict.type == "prefix" then
    desc = desc .. string.format(" (prefix: %s)", conflict.prefix)
  end

  return {
    text = desc,
    severity = type_info.severity,
    lhs = conflict.first.lhs,
    details = {
      first = conflict.first,
      second = conflict.second,
      type = conflict.type,
    },
  }
end

-- Get diagnostics-style conflict information
function M.get_conflict_diagnostics()
  local conflicts = M.detect_conflicts()
  local diagnostics = {}

  for _, conflict in ipairs(conflicts) do
    local formatted = M.format_conflict(conflict)
    table.insert(diagnostics, {
      lnum = 0,
      col = 0,
      message = formatted.text,
      severity = vim.diagnostic.severity[formatted.severity:upper()],
      source = "keymap-search",
    })
  end

  return diagnostics
end

-- Get conflict highlights for a keymap
function M.get_conflict_highlights(keymap)
  local highlights = {}
  local conflicts = M.detect_conflicts()

  for _, conflict in ipairs(conflicts) do
    if conflict.first.lhs == keymap.lhs or conflict.second.lhs == keymap.lhs then
      local type_info = M.conflict_types[conflict.type]
      table.insert(highlights, {
        icon = type_info.icon,
        desc = type_info.desc,
        hl = "KeywhizConflict" .. type_info.severity:gsub("^%l", string.upper),
      })
    end
  end

  return highlights
end

return M
