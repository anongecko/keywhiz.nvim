-- integrations/marks.lua
local M = {}

function M.setup()
  -- Track mark usage
  vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
      M.save_mark_history()
    end,
  })
end

-- Get all marks with descriptions
function M.get_marks()
  local marks = {}

  -- Get buffer marks
  for mark, pos in pairs(vim.fn.getmarklist(vim.api.nvim_get_current_buf())) do
    table.insert(marks, {
      mark = mark,
      pos = pos,
      type = "buffer",
      desc = M.get_mark_context(pos),
    })
  end

  -- Get global marks
  for mark, pos in pairs(vim.fn.getmarklist()) do
    if mark:match("[A-Z]") then
      table.insert(marks, {
        mark = mark,
        pos = pos,
        type = "global",
        desc = M.get_mark_context(pos),
      })
    end
  end

  return marks
end

-- Get registers with content previews
function M.get_registers()
  local registers = {}

  for _, reg in ipairs({ '"', "_", "*", "+", ":", ".", "%", "#", "=", "/" }) do
    local content = vim.fn.getreg(reg)
    if content and content ~= "" then
      table.insert(registers, {
        reg = reg,
        content = content,
        type = M.get_register_type(reg),
        desc = M.get_register_desc(reg),
      })
    end
  end

  -- Named registers
  for reg in string.gmatch("abcdefghijklmnopqrstuvwxyz", ".") do
    local content = vim.fn.getreg(reg)
    if content and content ~= "" then
      table.insert(registers, {
        reg = reg,
        content = content,
        type = "named",
        desc = M.get_register_desc(reg),
      })
    end
  end

  return registers
end

-- Get mark context
function M.get_mark_context(pos)
  local line = vim.fn.getline(pos[2])
  return line:sub(1, 50) .. (line:len() > 50 and "..." or "")
end

-- Get register type
function M.get_register_type(reg)
  local types = {
    ['"'] = "unnamed",
    ["*"] = "selection",
    ["+"] = "clipboard",
    ["_"] = "blackhole",
    [":"] = "command",
    ["."] = "last_inserted",
    ["%"] = "current_file",
    ["#"] = "alternate_file",
    ["="] = "expression",
    ["/"] = "search",
  }
  return types[reg] or "named"
end

-- Get register description
function M.get_register_desc(reg)
  local descriptions = {
    ['"'] = "Unnamed register (last yank/delete)",
    ["*"] = "Selection register (system)",
    ["+"] = "Clipboard register (system)",
    ["_"] = "Black hole register",
    [":"] = "Last command register",
    ["."] = "Last inserted text",
    ["%"] = "Current file name",
    ["#"] = "Alternate file name",
    ["="] = "Expression register",
    ["/"] = "Last search pattern",
  }
  return descriptions[reg] or "Named register"
end

return M
