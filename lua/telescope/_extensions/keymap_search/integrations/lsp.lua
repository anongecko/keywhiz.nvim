local M = {}

-- Cache LSP clients
local attached_clients = {}

function M.setup()
  -- Track LSP client attachments
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        attached_clients[args.buf] = attached_clients[args.buf] or {}
        attached_clients[args.buf][client.name] = client
      end
    end,
  })
end

-- Get LSP-specific keymaps for current buffer
function M.get_lsp_keymaps()
  local bufnr = vim.api.nvim_get_current_buf()
  local keymaps = {}

  if attached_clients[bufnr] then
    for client_name, client in pairs(attached_clients[bufnr]) do
      -- Common LSP mappings
      local lsp_mappings = {
        { mode = "n", lhs = "gd", desc = "Go to Definition", client = client_name },
        { mode = "n", lhs = "gr", desc = "Go to References", client = client_name },
        { mode = "n", lhs = "K", desc = "Hover Documentation", client = client_name },
        { mode = "n", lhs = "<leader>rn", desc = "Rename", client = client_name },
        { mode = "n", lhs = "<leader>ca", desc = "Code Action", client = client_name },
      }

      -- Add client-specific mappings
      if client.server_capabilities then
        if client.server_capabilities.documentFormattingProvider then
          table.insert(lsp_mappings, {
            mode = "n",
            lhs = "<leader>fm",
            desc = "Format Document",
            client = client_name,
          })
        end
        -- Add more capability-specific mappings
      end

      -- Add to keymaps list
      for _, map in ipairs(lsp_mappings) do
        table.insert(keymaps, map)
      end
    end
  end

  return keymaps
end

return M
