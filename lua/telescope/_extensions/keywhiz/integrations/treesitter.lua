-- lua/telescope/_extensions/keywhiz/integrations/treesitter.lua
local M = {}

-- Cache modules
local ts = vim.treesitter
local config = require("telescope._extensions.keywhiz.config")
local parsers = require("nvim-treesitter.parsers")
local queries = require("nvim-treesitter.query")
local ts_utils = require("nvim-treesitter.ts_utils")

-- Cache for parsed nodes and contexts
M.context_cache = {}
M.node_cache = {}

-- Language-specific node types for scope and context
M.scope_types = {
  lua = {
    scopes = {
      "function_declaration",
      "function_definition",
      "method_definition",
      "if_statement",
      "for_statement",
      "while_statement",
      "table_constructor",
    },
    contexts = {
      "variable_declaration",
      "assignment_statement",
      "return_statement",
      "function_call",
    },
  },
  python = {
    scopes = {
      "function_definition",
      "class_definition",
      "if_statement",
      "for_statement",
      "while_statement",
      "with_statement",
      "try_statement",
    },
    contexts = {
      "import_statement",
      "import_from_statement",
      "assignment",
      "call",
    },
  },
  javascript = {
    scopes = {
      "function_declaration",
      "class_declaration",
      "method_definition",
      "arrow_function",
      "if_statement",
      "for_statement",
      "while_statement",
      "try_statement",
    },
    contexts = {
      "variable_declaration",
      "lexical_declaration",
      "expression_statement",
      "return_statement",
    },
  },
  -- Add more language-specific configurations
}

-- Setup TreeSitter integration
function M.setup()
  -- Create autocommands for cache management
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
    callback = function(args)
      M.update_buffer_cache(args.buf)
    end,
  })

  -- Add highlighting queries for keymap-related nodes
  local highlight_query = [[
    (function_call
      name: (identifier) @function
      arguments: (arguments (string) @keymap)
      (#match? @function "^vim%.keymap%.set"))

    (assignment_statement
      variables: (variable_list (identifier) @variable)
      values: (expression_list (string) @keymap)
      (#match? @variable "_keys$"))
  ]]

  for _, lang in ipairs({ "lua", "vim" }) do
    if not queries.get_query(lang, "highlights") then
      queries.set_query(lang, "highlights", highlight_query)
    end
  end
end

-- Update buffer cache with latest TreeSitter information
function M.update_buffer_cache(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear existing cache for this buffer
  M.context_cache[bufnr] = {}
  M.node_cache[bufnr] = {}

  local parser = parsers.get_parser(bufnr)
  if not parser then
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  local root = tree:root()
  local lang = parsers.get_buf_lang(bufnr)
  local scope_config = M.scope_types[lang] or M.scope_types.lua

  -- Walk the syntax tree
  local function walk_tree(node, parent_scope)
    local type = node:type()

    -- Track scopes and contexts
    if vim.tbl_contains(scope_config.scopes, type) then
      local scope = {
        node = node,
        type = type,
        parent = parent_scope,
        start_row = node:start(),
        children = {},
      }

      if parent_scope then
        table.insert(parent_scope.children, scope)
      end

      M.context_cache[bufnr][node:id()] = scope
      parent_scope = scope
    end

    -- Cache node information
    if vim.tbl_contains(scope_config.contexts, type) then
      M.node_cache[bufnr][node:id()] = {
        node = node,
        type = type,
        scope = parent_scope,
        start_row = node:start(),
      }
    end

    -- Recurse through children
    for child in node:iter_children() do
      walk_tree(child, parent_scope)
    end
  end

  walk_tree(root, nil)
end

-- Get context information for a position
function M.get_context_at_pos(bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not M.context_cache[bufnr] then
    M.update_buffer_cache(bufnr)
  end

  local contexts = {}
  for _, scope in pairs(M.context_cache[bufnr]) do
    local start_row, start_col, end_row, end_col = scope.node:range()
    if row >= start_row and row <= end_row then
      table.insert(contexts, {
        type = scope.type,
        text = vim.treesitter.get_node_text(scope.node, bufnr),
        range = { start_row, start_col, end_row, end_col },
        depth = #contexts + 1,
      })
    end
  end

  return contexts
end

-- Get relevant keymaps for current context
function M.get_context_keymaps()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local contexts = M.get_context_at_pos(bufnr, cursor[1] - 1, cursor[2])

  local keymaps = {}
  local lang = parsers.get_buf_lang(bufnr)

  -- Language-specific keymaps
  local lang_maps = {
    python = {
      ["]]"] = "Next class/function",
      ["[["] = "Previous class/function",
      ["zc"] = "Fold class/function",
      ["zo"] = "Unfold class/function",
    },
    lua = {
      ["]m"] = "Next function",
      ["[m"] = "Previous function",
      ["]]"] = "Next block",
      ["[["] = "Previous block",
    },
    javascript = {
      ["]c"] = "Next class",
      ["[c"] = "Previous class",
      ["]m"] = "Next method",
      ["[m"] = "Previous method",
    },
  }

  -- Add language-specific maps
  if lang_maps[lang] then
    for lhs, desc in pairs(lang_maps[lang]) do
      table.insert(keymaps, {
        lhs = lhs,
        desc = desc,
        mode = "n",
        source = "treesitter",
        lang = lang,
      })
    end
  end

  -- Context-specific keymaps
  for _, context in ipairs(contexts) do
    -- Fold-related keymaps
    if vim.tbl_contains({ "function_definition", "class_definition" }, context.type) then
      table.insert(keymaps, {
        lhs = "zc",
        desc = "Fold " .. context.type:gsub("_", " "),
        mode = "n",
        context = context,
      })
      table.insert(keymaps, {
        lhs = "zo",
        desc = "Unfold " .. context.type:gsub("_", " "),
        mode = "n",
        context = context,
      })
    end

    -- Text object keymaps
    if vim.tbl_contains({ "function_definition", "class_definition", "method_definition" }, context.type) then
      table.insert(keymaps, {
        lhs = "af",
        desc = "Around function/class",
        mode = "o",
        context = context,
      })
      table.insert(keymaps, {
        lhs = "if",
        desc = "Inside function/class",
        mode = "o",
        context = context,
      })
    end
  end

  return keymaps
end

-- Get preview information for TreeSitter context
function M.get_preview_info(keymap)
  if not keymap.context then
    return {}
  end

  local lines = {
    "# TreeSitter Context",
    "",
  }

  -- Add context hierarchy
  local current = keymap.context
  local hierarchy = {}
  while current do
    table.insert(hierarchy, 1, {
      type = current.type,
      text = vim.trim(current.text:gsub("\n", " ")):sub(1, 50),
      depth = #hierarchy + 1,
    })
    current = current.parent
  end

  for _, item in ipairs(hierarchy) do
    table.insert(
      lines,
      string.format("%s%s: %s", string.rep("  ", item.depth - 1), item.type:gsub("_", " "), item.text)
    )
  end

  -- Add available commands in context
  if keymap.context.type then
    table.insert(lines, "")
    table.insert(lines, "Available commands in context:")
    table.insert(lines, "")

    local context_maps = M.get_context_keymaps()
    for _, map in ipairs(context_maps) do
      if map.context and map.context.type == keymap.context.type then
        table.insert(lines, string.format("  %s → %s", map.lhs, map.desc))
      end
    end
  end

  return lines
end

-- Get entry information for the picker
function M.get_entry_info(keymap)
  if not keymap.context then
    return nil
  end

  return string.format("Context: %s", keymap.context.type:gsub("_", " "))
end

-- Get diagnostic information from TreeSitter
function M.get_diagnostics(bufnr)
  local diagnostics = {}

  -- Check for parser errors
  local parser = parsers.get_parser(bufnr)
  if parser then
    local tree = parser:parse()[1]
    if tree then
      local has_error = false
      tree:for_each_tree(function(tree)
        if tree:has_error() then
          has_error = true
        end
      end)

      if has_error then
        table.insert(diagnostics, {
          lnum = 0,
          col = 0,
          message = "TreeSitter parser encountered errors",
          severity = vim.diagnostic.severity.WARN,
        })
      end
    end
  end

  return diagnostics
end

-- Get commands for command palette
function M.get_commands()
  return {
    {
      name = "TSContextToggle",
      desc = "Toggle TreeSitter context display",
      execute = function()
        -- Implementation
      end,
    },
    {
      name = "TSHighlightCapturesUnderCursor",
      desc = "Show TreeSitter highlight groups",
      execute = function()
        -- Implementation
      end,
    },
  }
end

return M
