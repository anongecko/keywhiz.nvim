-- integrations/session.lua
local M = {}

-- Session state
M.current_session = nil
M.session_dir = vim.fn.stdpath("data") .. "/keywhiz/sessions"

function M.setup()
  -- Create session directory
  vim.fn.mkdir(M.session_dir, "p")

  -- Auto-save session on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M.current_session then
        M.save_session(M.current_session)
      end
    end,
  })

  -- Track session-specific keymaps
  vim.api.nvim_create_autocmd("SessionLoadPost", {
    callback = function()
      M.load_session_keymaps()
    end,
  })
end

function M.save_session(name)
  local session_file = M.session_dir .. "/" .. name .. ".vim"

  -- Save current keymaps
  local keymaps = M.get_current_keymaps()
  local keymap_file = M.session_dir .. "/" .. name .. ".keymaps.json"

  vim.fn.writefile({ vim.json.encode(keymaps) }, keymap_file)

  -- Save session
  vim.cmd("mksession! " .. session_file)
  M.current_session = name
end

function M.load_session(name)
  local session_file = M.session_dir .. "/" .. name .. ".vim"
  local keymap_file = M.session_dir .. "/" .. name .. ".keymaps.json"

  if vim.fn.filereadable(session_file) == 1 then
    vim.cmd("source " .. session_file)
    M.current_session = name

    -- Restore session keymaps
    if vim.fn.filereadable(keymap_file) == 1 then
      local content = vim.fn.readfile(keymap_file)
      local keymaps = vim.json.decode(content[1])
      M.restore_keymaps(keymaps)
    end
  end
end

function M.get_current_keymaps()
  local keymaps = {}
  for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "t", "c" }) do
    keymaps[mode] = vim.api.nvim_get_keymap(mode)
  end
  return keymaps
end

function M.restore_keymaps(keymaps)
  for mode, maps in pairs(keymaps) do
    for _, map in ipairs(maps) do
      vim.keymap.set(mode, map.lhs, map.rhs, {
        silent = map.silent,
        expr = map.expr,
        desc = map.desc,
      })
    end
  end
end

-- Session management commands
function M.get_session_commands()
  return {
    { cmd = "SaveSession", desc = "Save current session" },
    { cmd = "LoadSession", desc = "Load session" },
    { cmd = "DeleteSession", desc = "Delete session" },
    { cmd = "ListSessions", desc = "List all sessions" },
  }
end

return M
