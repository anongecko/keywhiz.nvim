local M = {}
local config = require("telescope._extensions.keymap_search.config")
local favorites = require("telescope._extensions.keymap_search.favorites")
local history = require("telescope._extensions.keymap_search.history")
local utils = require("telescope._extensions.keymap_search.utils")

-- Execute a keymap
function M.execute_keymap(keymap)
  if not keymap or not keymap.lhs then
    return
  end

  -- Save to history before execution
  history.add_entry(keymap)

  -- Get the mode and keys
  local mode = keymap.mode or "n"
  local keys = keymap.lhs

  -- Handle special cases (buffer-local, expressions)
  if keymap.buffer then
    local bufnr = keymap.buffer
    if type(keymap.rhs) == "function" then
      keymap.rhs()
    else
      vim.api.nvim_buf_call(bufnr, function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode, true)
      end)
    end
    return
  end

  -- Execute the keymap
  if type(keymap.rhs) == "function" then
    keymap.rhs()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode, true)
  end
end

-- Edit keymap functionality
function M.edit_keymap(keymap)
  if not config.get_config().features.enable_edit then
    return
  end

  -- Create temporary buffer for editing
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.6)
  local height = 10
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create floating window
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Edit Keymap",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(bufnr, true, opts)

  -- Prepare content
  local lines = {
    "# Edit Keymap (Save: <CR>, Cancel: <Esc>)",
    "",
    string.format("Mode:        %s", keymap.mode or "n"),
    string.format("Keys:        %s", keymap.lhs or ""),
    string.format("Description: %s", keymap.desc or ""),
    "",
    "# Modifications will be saved to your config",
  }

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Set up buffer options
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

  -- Add buffer mappings
  local function save_changes()
    local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_keymap = {
      mode = new_lines[3]:match("Mode:%s*(.+)"),
      lhs = new_lines[4]:match("Keys:%s*(.+)"),
      desc = new_lines[5]:match("Description:%s*(.+)"),
    }

    M.update_keymap(keymap, new_keymap)
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.notify("Keymap updated successfully", vim.log.levels.INFO)
  end

  local function cancel_edit()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end

  vim.keymap.set("n", "<CR>", save_changes, { buffer = bufnr })
  vim.keymap.set("n", "<Esc>", cancel_edit, { buffer = bufnr })
end

-- Update an existing keymap
function M.update_keymap(old_keymap, new_keymap)
  -- Remove old keymap
  if old_keymap.buffer then
    vim.keymap.del(old_keymap.mode, old_keymap.lhs, { buffer = old_keymap.buffer })
  else
    vim.keymap.del(old_keymap.mode, old_keymap.lhs)
  end

  -- Create new keymap
  vim.keymap.set(new_keymap.mode, new_keymap.lhs, old_keymap.rhs or old_keymap.callback, {
    desc = new_keymap.desc,
    buffer = old_keymap.buffer,
    expr = old_keymap.expr,
    silent = old_keymap.silent,
    nowait = old_keymap.nowait,
  })

  -- Update in history and favorites if present
  history.update_keymap(old_keymap, new_keymap)
  favorites.update_keymap(old_keymap, new_keymap)
end

-- Toggle favorite status
function M.toggle_favorite(keymap)
  if favorites.is_favorite(keymap) then
    favorites.remove_entry(keymap)
    vim.notify("Removed from favorites", vim.log.levels.INFO)
  else
    favorites.add_entry(keymap)
    vim.notify("Added to favorites", vim.log.levels.INFO)
  end
end

-- Copy keymap to clipboard
function M.copy_keymap(keymap)
  local text = string.format("%s - %s", keymap.lhs, keymap.desc or "")
  vim.fn.setreg("+", text)
  vim.notify("Keymap copied to clipboard", vim.log.levels.INFO)
end

return M
