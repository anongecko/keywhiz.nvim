local M = {}
local config = require("telescope._extensions.keywhiz.config")
local utils = require("telescope._extensions.keywhiz.utils")

-- Define category patterns and rules
M.category_rules = {
  movement = {
    patterns = {
      "^[hjkl]$",
      "^[wb]$",
      "move",
      "jump",
      "scroll",
      "goto",
      "[{}]",
      "[()]]",
      "[[]]",
    },
    keywords = { "next", "prev", "forward", "backward", "up", "down", "left", "right" },
  },

  edit = {
    patterns = {
      "^[cdy].",
      "insert",
      "change",
      "delete",
      "yank",
      "put",
      "paste",
    },
    keywords = { "modify", "replace", "substitute", "edit" },
  },

  lsp = {
    patterns = {
      "^g[dDr]",
      "hover",
      "rename",
      "format",
      "diagnostic",
      "reference",
      "definition",
      "implementation",
    },
    keywords = { "lsp", "code", "symbol", "signature" },
  },

  window = {
    patterns = {
      "^<C%-w>",
      "split",
      "vsplit",
      "close",
      "window",
      "tab",
      "buffer",
    },
    keywords = { "resize", "focus", "zoom", "layout" },
  },

  file = {
    patterns = {
      "find[_ ]file",
      "save",
      "write",
      "quit",
      "file",
      "directory",
    },
    keywords = { "open", "close", "create", "delete", "rename" },
  },

  search = {
    patterns = {
      "^[/?]",
      "search",
      "find",
      "grep",
      "replace",
    },
    keywords = { "pattern", "match", "locate" },
  },

  git = {
    patterns = {
      "git",
      "diff",
      "branch",
      "commit",
      "stage",
      "blame",
    },
    keywords = { "merge", "rebase", "pull", "push" },
  },
}

-- Function to categorize a keymap
function M.categorize_keymap(keymap)
  local categories = {}
  local desc = (keymap.desc or ""):lower()
  local lhs = (keymap.lhs or ""):lower()

  for category, rules in pairs(M.category_rules) do
    -- Check patterns
    for _, pattern in ipairs(rules.patterns) do
      if lhs:match(pattern) or desc:match(pattern) then
        table.insert(categories, category)
        break
      end
    end

    -- Check keywords if not already categorized
    if not vim.tbl_contains(categories, category) then
      for _, keyword in ipairs(rules.keywords) do
        if desc:match(keyword) then
          table.insert(categories, category)
          break
        end
      end
    end
  end

  return #categories > 0 and categories or { "misc" }
end

-- Get alternative keymaps for a given keymap
function M.get_alternatives(keymap)
  local alternatives = {}
  local categories = M.categorize_keymap(keymap)

  -- Get all keymaps
  local all_maps = vim.api.nvim_get_keymap("")
  for _, map in ipairs(all_maps) do
    -- Skip the original keymap
    if map.lhs ~= keymap.lhs then
      local map_categories = M.categorize_keymap(map)
      -- Check for category overlap
      for _, category in ipairs(categories) do
        if vim.tbl_contains(map_categories, category) then
          table.insert(alternatives, map)
          break
        end
      end
    end
  end

  return alternatives
end

-- Check if keymap matches a category filter
function M.matches_filter(keymap, filter)
  local parts = vim.split(filter, ":", { plain = true })
  local filter_type = parts[1]
  local filter_value = parts[2]

  if filter_type == "category" then
    local categories = M.categorize_keymap(keymap)
    return vim.tbl_contains(categories, filter_value)
  end

  return false
end

return M
