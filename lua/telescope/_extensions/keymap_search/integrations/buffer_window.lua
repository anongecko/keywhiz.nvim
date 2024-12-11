-- integrations/buffer_window.lua
local M = {}

local function get_window_layout()
  -- Get current layout information
  local layout = vim.fn.winlayout()
  local layout_type = layout[1]
  local layout_info = layout[2]

  -- Track windows and their buffers
  local windows = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    table.insert(windows, {
      id = win,
      buffer = buf,
      buffer_name = vim.fn.bufname(buf),
      is_current = win == vim.api.nvim_get_current_win(),
      layout_type = layout_type,
      position = vim.api.nvim_win_get_position(win),
    })
  end

  return windows
end

function M.setup()
  -- Track window and buffer changes
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinClosed" }, {
    callback = function()
      M.current_layout = get_window_layout()
      M.update_window_keymaps()
    end,
  })
end

function M.update_window_keymaps()
  local layout = M.current_layout
  local keymaps = {}

  -- Basic window commands
  local basic_maps = {
    { lhs = "<C-w>v", desc = "Split vertical" },
    { lhs = "<C-w>s", desc = "Split horizontal" },
    { lhs = "<C-w>q", desc = "Close window" },
    { lhs = "<C-w>o", desc = "Close other windows" },
  }

  -- Navigation commands
  local nav_maps = {
    { lhs = "<C-w>h", desc = "Go to left window" },
    { lhs = "<C-w>j", desc = "Go to window below" },
    { lhs = "<C-w>k", desc = "Go to window above" },
    { lhs = "<C-w>l", desc = "Go to right window" },
  }

  -- Resize commands
  local resize_maps = {
    { lhs = "<C-w>>", desc = "Increase width" },
    { lhs = "<C-w><", desc = "Decrease width" },
    { lhs = "<C-w>+", desc = "Increase height" },
    { lhs = "<C-w>-", desc = "Decrease height" },
    { lhs = "<C-w>=", desc = "Equal dimensions" },
  }

  -- Buffer commands
  local buffer_maps = {
    { lhs = ":bn<CR>", desc = "Next buffer" },
    { lhs = ":bp<CR>", desc = "Previous buffer" },
    { lhs = ":b#<CR>", desc = "Alternate buffer" },
    { lhs = ":bd<CR>", desc = "Delete buffer" },
  }

  -- Context-specific commands
  if #layout > 1 then
    table.insert(keymaps, { lhs = "<C-w>T", desc = "Break out into tab" })
  end

  if vim.fn.winnr("$") > 1 then
    table.insert(keymaps, { lhs = "<C-w>r", desc = "Rotate windows" })
    table.insert(keymaps, { lhs = "<C-w>x", desc = "Swap with next" })
  end

  -- Combine all maps
  vim.list_extend(keymaps, basic_maps)
  vim.list_extend(keymaps, nav_maps)
  vim.list_extend(keymaps, resize_maps)
  vim.list_extend(keymaps, buffer_maps)

  return keymaps
end

-- Get window-specific commands
function M.get_window_commands(win_id)
  local commands = {}
  local win_config = vim.api.nvim_win_get_config(win_id)

  if win_config.relative == "" then
    -- Normal window commands
    return {
      { cmd = "close", desc = "Close window" },
      { cmd = "only", desc = "Close other windows" },
      { cmd = "split", desc = "Split horizontally" },
      { cmd = "vsplit", desc = "Split vertically" },
    }
  else
    -- Floating window commands
    return {
      { cmd = "close", desc = "Close floating window" },
      { cmd = "resize", desc = "Resize window" },
      { cmd = "move", desc = "Move window" },
    }
  end
end

-- Get buffer-specific commands
function M.get_buffer_commands(buf_id)
  local commands = {}
  local buf_type = vim.api.nvim_buf_get_option(buf_id, "buftype")

  if buf_type == "" then
    -- Normal buffer commands
    table.insert(commands, { cmd = "write", desc = "Save buffer" })
    table.insert(commands, { cmd = "edit", desc = "Reload buffer" })
  elseif buf_type == "terminal" then
    -- Terminal buffer commands
    table.insert(commands, { cmd = "terminal", desc = "Terminal commands" })
  end

  return commands
end

return M
