local M = {}

-- Cache frequently used modules
local config = require("telescope._extensions.keywhiz.config")

-- Enhanced key type detection
function M.get_key_type(lhs)
  if type(lhs) ~= "string" then
    return "normal"
  end

  local patterns = {
    ["^<leader>"] = "leader",
    ["^<[Cc][Rr]>"] = "special",
    ["^<[Cc]-"] = "ctrl",
    ["^<[Mm]-"] = "alt",
    ["^<[Ss]-"] = "shift",
    ["^<[Ff]%d+>"] = "function",
    ["^g[dDrR]"] = "lsp",
    ["^[\"']"] = "register",
    ["^z"] = "fold",
  }

  for pattern, type_ in pairs(patterns) do
    if lhs:match(pattern) then
      return type_
    end
  end
  return "normal"
end

-- Enhanced key formatting with icons
function M.format_key_combination(lhs)
  local key_type = M.get_key_type(lhs)
  local color = config.get_color(key_type)
  local icon = config.get_config().icons[key_type] or ""
  return string.format("%%#KeymapSearch%s#%s%s%%#Normal#", key_type:gsub("^%l", string.upper), icon, lhs)
end

-- Comprehensive keymap display formatting
function M.format_keymap_display(keymap, is_favorite)
  if not keymap then
    return ""
  end

  -- Use passed favorite status
  local favorite_icon = is_favorite and "★ " or "  "

  -- Rest of the function remains the same
  local formatted_key = M.format_key_combination(keymap.lhs or "")
  local source = M.get_keymap_source(keymap)
  local source_icon = config.get_config().icons.sources[source] or ""
  local mode = keymap.mode or "n"
  local mode_icon = config.get_config().icons.modes[mode] or mode
  local context = M.get_keymap_context(keymap)
  local context_display = context and string.format(" [%s]", context) or ""
  local category = M.get_keymap_category(keymap)
  local category_icon = config.get_config().icons.categories[category] or ""

  return string.format(
    "%s%s %s %s %s%s %s%s",
    favorite_icon,
    formatted_key,
    mode_icon,
    keymap.desc or "",
    source_icon,
    source,
    category_icon,
    context_display
  )
end

-- Enhanced source detection
function M.get_keymap_source(keymap)
  if keymap.plugin then
    return keymap.plugin
  end
  if keymap.buffer then
    return "buffer"
  end

  -- Try to determine source from the mapping
  if keymap.callback then
    local info = debug.getinfo(keymap.callback, "S")
    if info and info.source then
      local source = info.source:gsub("^@", "")

      -- Check for known sources
      local sources = {
        ["nvim"] = "built%-in",
        ["nvchad"] = "nvchad",
        ["custom"] = "custom",
        ["/plugins/(.-)/.+"] = "%1", -- Plugin name
      }

      for pattern, replacement in pairs(sources) do
        local match = source:match(pattern)
        if match then
          return type(replacement) == "string" and replacement or match
        end
      end
    end
  end

  return "unknown"
end

-- Enhanced context detection
function M.get_keymap_context(keymap)
  local contexts = {}

  -- Check various contexts
  local context_checks = {
    buffer = function(k)
      return k.buffer and "buffer-local"
    end,
    expr = function(k)
      return k.expr and "expression"
    end,
    nowait = function(k)
      return k.nowait and "nowait"
    end,
    silent = function(k)
      return k.silent and "silent"
    end,
    filetype = function(k)
      return k.ft and "ft:" .. k.ft
    end,
    plugin = function(k)
      return k.plugin and "plugin:" .. k.plugin
    end,
  }

  for _, check in pairs(context_checks) do
    local context = check(keymap)
    if context then
      table.insert(contexts, context)
    end
  end

  return #contexts > 0 and table.concat(contexts, ", ") or nil
end

-- Get keymap under cursor
function M.get_keymap_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Try to extract keymap from line
  local keymap_pattern = "<[^>]+>|%S+"
  local start = 1
  while start <= #line do
    local s, e = line:find(keymap_pattern, start)
    if not s then
      break
    end
    if col >= s and col <= e then
      local key = line:sub(s, e)
      -- Find matching keymap
      local mode = vim.api.nvim_get_mode().mode
      local maps = vim.api.nvim_get_keymap(mode)
      for _, map in ipairs(maps) do
        if map.lhs == key then
          return map
        end
      end
    end
    start = e + 1
  end
  return nil
end

-- Keymap category detection
function M.get_keymap_category(keymap)
  if keymap.category then
    return keymap.category
  end

  local desc = (keymap.desc or ""):lower()
  local lhs = (keymap.lhs or ""):lower()

  -- Define category patterns
  local categories = require("telescope._extensions.keywhiz.categories").category_rules

  for category, rules in pairs(categories) do
    -- Check patterns
    for _, pattern in ipairs(rules.patterns) do
      if lhs:match(pattern) or desc:match(pattern) then
        return category
      end
    end

    -- Check keywords
    for _, keyword in ipairs(rules.keywords or {}) do
      if desc:match(keyword) then
        return category
      end
    end
  end

  return "misc"
end

-- Utility functions
M.escape_pattern = function(str)
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

M.tbl_compare = function(t1, t2, ignore_keys)
  if t1 == t2 then
    return true
  end
  if type(t1) ~= "table" or type(t2) ~= "table" then
    return false
  end

  ignore_keys = ignore_keys or {}
  local ignore_set = {}
  for _, key in ipairs(ignore_keys) do
    ignore_set[key] = true
  end

  for k, v1 in pairs(t1) do
    if not ignore_set[k] then
      local v2 = t2[k]
      if not v2 or not M.tbl_compare(v1, v2, ignore_keys) then
        return false
      end
    end
  end

  for k in pairs(t2) do
    if not ignore_set[k] and t1[k] == nil then
      return false
    end
  end

  return true
end

return M
