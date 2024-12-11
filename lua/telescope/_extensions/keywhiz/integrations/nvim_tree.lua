-- lua/telescope/_extensions/keywhiz/integrations/nvim_tree.lua
local M = {}

-- Cache modules
local config = require("telescope._extensions.keywhiz.config")
local utils = require("telescope._extensions.keywhiz.utils")

-- Cache for NvimTree state
M.tree_state = {
  is_open = false,
  current_node = nil,
  buffer = nil,
}

-- Define NvimTree-specific actions and their descriptions
M.actions = {
  basic = {
    { lhs = "o", desc = "Open file or expand directory" },
    { lhs = "<CR>", desc = "Open file or expand directory" },
    { lhs = "l", desc = "Open file or expand directory" },
    { lhs = "h", desc = "Close directory" },
    { lhs = "v", desc = "Open in vertical split" },
    { lhs = "s", desc = "Open in horizontal split" },
    { lhs = "t", desc = "Open in new tab" },
    { lhs = "<C-t>", desc = "Open in new tab silently" },
    { lhs = "I", desc = "Toggle hidden files" },
    { lhs = "H", desc = "Toggle dotfiles" },
    { lhs = "R", desc = "Refresh tree" },
    { lhs = "?", desc = "Toggle help" },
  },
  file_operations = {
    { lhs = "a", desc = "Create new file/directory" },
    { lhs = "d", desc = "Delete file/directory" },
    { lhs = "r", desc = "Rename file/directory" },
    { lhs = "x", desc = "Cut file/directory" },
    { lhs = "c", desc = "Copy file/directory" },
    { lhs = "p", desc = "Paste file/directory" },
    { lhs = "y", desc = "Copy file name" },
    { lhs = "Y", desc = "Copy relative path" },
    { lhs = "gy", desc = "Copy absolute path" },
  },
  tree_navigation = {
    { lhs = "<C-]>", desc = "CD into directory" },
    { lhs = "-", desc = "Navigate to parent directory" },
    { lhs = "q", desc = "Close tree" },
    { lhs = "W", desc = "Collapse all" },
    { lhs = "E", desc = "Expand all" },
    { lhs = "F", desc = "Clean filter" },
    { lhs = "f", desc = "Filter tree" },
    { lhs = "B", desc = "Toggle no buffer" },
    { lhs = "g?", desc = "Toggle help" },
  },
  git_operations = {
    { lhs = "[c", desc = "Previous git item" },
    { lhs = "]c", desc = "Next git item" },
    { lhs = "gc", desc = "Git commit" },
    { lhs = "gp", desc = "Git push" },
  },
  marks_bookmarks = {
    { lhs = "m", desc = "Toggle bookmark" },
    { lhs = "bd", desc = "Delete bookmark" },
    { lhs = "bt", desc = "Bookmark toggle" },
    { lhs = "bl", desc = "Bookmark list" },
  },
}

-- Setup NvimTree integration
function M.setup()
  -- Check if NvimTree is available
  local ok, nvim_tree = pcall(require, "nvim-tree")
  if not ok then
    return
  end

  -- Track NvimTree state
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "NvimTree",
    callback = function(args)
      M.tree_state.is_open = true
      M.tree_state.buffer = args.buf
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "NvimTree",
    callback = function()
      M.tree_state.is_open = false
    end,
  })

  -- Track cursor node
  if ok then
    local api = require("nvim-tree.api")
    api.events.subscribe(api.events.Event.NodeCursorMoved, function(node)
      M.tree_state.current_node = node
    end)
  end
end

-- Get all NvimTree keymaps
function M.get_keymaps()
  local keymaps = {}

  -- Helper to add keymaps with context
  local function add_keymaps(maps, category)
    for _, map in ipairs(maps) do
      table.insert(
        keymaps,
        vim.tbl_extend("force", map, {
          mode = "n",
          category = category,
          source = "nvim-tree",
          requires_tree = true,
        })
      )
    end
  end

  -- Add all categories of keymaps
  add_keymaps(M.actions.basic, "basic")
  add_keymaps(M.actions.file_operations, "file_operations")
  add_keymaps(M.actions.tree_navigation, "tree_navigation")
  add_keymaps(M.actions.git_operations, "git")
  add_keymaps(M.actions.marks_bookmarks, "marks")

  -- Add context-specific keymaps based on current node
  if M.tree_state.current_node then
    local node = M.tree_state.current_node
    if node.type == "directory" then
      table.insert(keymaps, {
        lhs = "o",
        desc = "Expand directory: " .. node.name,
        mode = "n",
        category = "context",
        source = "nvim-tree",
        requires_tree = true,
      })
    elseif node.type == "file" then
      table.insert(keymaps, {
        lhs = "o",
        desc = "Open file: " .. node.name,
        mode = "n",
        category = "context",
        source = "nvim-tree",
        requires_tree = true,
      })
    end
  end

  return keymaps
end

-- Get preview information for a keymap
function M.get_preview_info(keymap)
  if keymap.source ~= "nvim-tree" then
    return {}
  end

  local lines = {
    "# NvimTree Information",
    "",
  }

  -- Add category information
  if keymap.category then
    table.insert(lines, string.format("Category: %s", keymap.category))
    table.insert(lines, "")
  end

  -- Add current context if available
  if M.tree_state.current_node then
    local node = M.tree_state.current_node
    table.insert(lines, "Current Node:")
    table.insert(lines, string.format("  Type: %s", node.type))
    table.insert(lines, string.format("  Name: %s", node.name))
    if node.absolute_path then
      table.insert(lines, string.format("  Path: %s", node.absolute_path))
    end
    table.insert(lines, "")
  end

  -- Add related commands
  table.insert(lines, "Related Commands:")
  for _, map in ipairs(M.actions[keymap.category] or {}) do
    table.insert(lines, string.format("  %s → %s", map.lhs, map.desc))
  end

  return lines
end

-- Get entry information for the picker
function M.get_entry_info(keymap)
  if keymap.source ~= "nvim-tree" then
    return nil
  end

  if M.tree_state.current_node then
    return string.format("NvimTree [%s: %s]", M.tree_state.current_node.type, M.tree_state.current_node.name)
  end

  return "NvimTree"
end

-- Get command palette entries
function M.get_commands()
  return {
    {
      name = "NvimTreeToggle",
      desc = "Toggle file explorer",
      execute = function()
        vim.cmd("NvimTreeToggle")
      end,
    },
    {
      name = "NvimTreeFocus",
      desc = "Focus file explorer",
      execute = function()
        vim.cmd("NvimTreeFocus")
      end,
    },
    {
      name = "NvimTreeRefresh",
      desc = "Refresh file explorer",
      execute = function()
        vim.cmd("NvimTreeRefresh")
      end,
    },
    {
      name = "NvimTreeFindFile",
      desc = "Find current file in explorer",
      execute = function()
        vim.cmd("NvimTreeFindFile")
      end,
    },
  }
end

return M
