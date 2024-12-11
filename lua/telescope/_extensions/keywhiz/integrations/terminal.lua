-- integrations/terminal.lua
local M = {}

-- Terminal state
M.terminals = {}
M.current_terminal = nil

function M.setup()
  -- Track terminal buffers
  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(args)
      local buf = args.buf
      M.terminals[buf] = {
        id = buf,
        pid = vim.fn.jobpid(vim.b[buf].terminal_job_id),
        name = vim.fn.bufname(buf),
        created = os.time(),
      }
    end,
  })

  -- Clean up closed terminals
  vim.api.nvim_create_autocmd("TermClose", {
    callback = function(args)
      M.terminals[args.buf] = nil
    end,
  })
end

-- Get terminal-specific keymaps
function M.get_terminal_keymaps()
  return {
    -- Terminal mode mappings
    { mode = "t", lhs = "<C-\\><C-n>", desc = "Enter Normal mode" },
    { mode = "t", lhs = "<C-w>", desc = "Terminal window command" },
    { mode = "t", lhs = "<C-c>", desc = "Send SIGINT" },
    { mode = "t", lhs = "<C-d>", desc = "Send EOF" },

    -- Normal mode mappings for terminals
    { mode = "n", lhs = "<leader>tt", desc = "Toggle terminal" },
    { mode = "n", lhs = "<leader>tn", desc = "New terminal" },
    { mode = "n", lhs = "<leader>tk", desc = "Kill terminal" },
    { mode = "n", lhs = "<leader>tc", desc = "Clear terminal" },
  }
end

-- Terminal management functions
function M.create_terminal()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "terminal")
  vim.fn.termopen(vim.o.shell)
  return buf
end

function M.toggle_terminal()
  if M.current_terminal and vim.api.nvim_buf_is_valid(M.current_terminal) then
    local win = vim.fn.bufwinid(M.current_terminal)
    if win ~= -1 then
      vim.api.nvim_win_hide(win)
    else
      M.show_terminal(M.current_terminal)
    end
  else
    local buf = M.create_terminal()
    M.current_terminal = buf
    M.show_terminal(buf)
  end
end

function M.show_terminal(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.cmd("startinsert")
end

-- Get terminal commands
function M.get_terminal_commands()
  return {
    { cmd = "term", desc = "Open terminal" },
    { cmd = "terminal", desc = "Open terminal (full)" },
    { cmd = "vs term", desc = "Open terminal (vertical split)" },
    { cmd = "sp term", desc = "Open terminal (horizontal split)" },
  }
end

return M
