local M = {}
local config = require("telescope._extensions.keymap_search.config")
local utils = require("telescope._extensions.keymap_search.utils")

local history_file

function M.setup(cache_dir)
  history_file = cache_dir .. "/history.json"
end

-- Add entry to history
function M.add_entry(keymap)
  local history = M.get_entries()

  -- Create new entry
  local entry = {
    lhs = keymap.lhs,
    desc = keymap.desc,
    mode = keymap.mode,
    timestamp = os.time(),
    source = utils.get_keymap_source(keymap),
    context = utils.get_keymap_context(keymap),
  }

  -- Remove duplicates
  for i = #history, 1, -1 do
    if utils.tbl_compare(history[i], entry, { "timestamp" }) then
      table.remove(history, i)
    end
  end

  -- Add new entry at the beginning
  table.insert(history, 1, entry)

  -- Trim history to max size
  while #history > config.get_config().history.max_entries do
    table.remove(history)
  end

  M.save_entries(history)
end

function M.get_entries()
  if not config.get_config().history.save_to_disk then
    return {}
  end

  local ok, content = pcall(vim.fn.readfile, history_file)
  if not ok then
    return {}
  end

  -- Parse and validate JSON
  local ok, history = pcall(vim.json.decode, content[1] or "[]")
  if not ok then
    return {}
  end

  return history
end

function M.save_entries(history)
  if not config.get_config().history.save_to_disk then
    return
  end

  local ok, encoded = pcall(vim.json.encode, history)
  if not ok then
    return
  end

  vim.fn.writefile({ encoded }, history_file)
end

-- Get history for a specific keymap
function M.get_keymap_history(keymap)
  local history = M.get_entries()
  local keymap_history = {}

  for _, entry in ipairs(history) do
    if entry.lhs == keymap.lhs and entry.mode == keymap.mode then
      table.insert(keymap_history, entry)
    end
  end

  return keymap_history
end

return M
