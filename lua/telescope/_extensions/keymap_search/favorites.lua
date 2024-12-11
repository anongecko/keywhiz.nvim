local M = {}
local config = require("telescope._extensions.keymap_search.config")
local utils = require("telescope._extensions.keymap_search.utils")

local favorites_file

function M.setup(cache_dir)
  favorites_file = cache_dir .. "/favorites.json"
end

function M.add_entry(keymap)
  local favorites = M.get_entries()

  -- Create new entry
  local entry = {
    lhs = keymap.lhs,
    desc = keymap.desc,
    mode = keymap.mode,
    source = utils.get_keymap_source(keymap),
    context = utils.get_keymap_context(keymap),
  }

  -- Check if already exists
  for _, fav in ipairs(favorites) do
    if utils.tbl_compare(fav, entry) then
      return
    end
  end

  table.insert(favorites, entry)

  -- Trim if exceeds max
  while #favorites > config.get_config().favorites.max_entries do
    table.remove(favorites, 1)
  end

  M.save_entries(favorites)
end

function M.remove_entry(keymap)
  local favorites = M.get_entries()

  for i, fav in ipairs(favorites) do
    if fav.lhs == keymap.lhs and fav.mode == keymap.mode then
      table.remove(favorites, i)
      break
    end
  end

  M.save_entries(favorites)
end

function M.get_entries()
  if not config.get_config().favorites.save_to_disk then
    return {}
  end

  local ok, content = pcall(vim.fn.readfile, favorites_file)
  if not ok then
    return {}
  end

  local ok, favorites = pcall(vim.json.decode, content[1] or "[]")
  if not ok then
    return {}
  end

  return favorites
end

function M.save_entries(favorites)
  if not config.get_config().favorites.save_to_disk then
    return
  end

  local ok, encoded = pcall(vim.json.encode, favorites)
  if not ok then
    return
  end

  vim.fn.writefile({ encoded }, favorites_file)
end

function M.is_favorite(keymap)
  local favorites = M.get_entries()

  for _, fav in ipairs(favorites) do
    if fav.lhs == keymap.lhs and fav.mode == keymap.mode then
      return true
    end
  end

  return false
end

return M
