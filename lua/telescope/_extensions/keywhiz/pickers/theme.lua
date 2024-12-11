local M = {}

-- Import required modules
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local themes = require("telescope._extensions.keywhiz.themes")
local conf = require("telescope.config").values

function M.theme_switcher()
  local theme_list = {}
  for name, theme in pairs(themes.themes) do
    table.insert(theme_list, {
      name = name,
      theme = theme,
    })
  end

  local function apply_highlights(bufnr, theme)
    local ns_id = vim.api.nvim_create_namespace("keywhiz_theme_preview")
    local highlights = {
      { pattern = "Normal Text", hl = "KeywhizNormal" },
      { pattern = "Leader Keys:", hl = "KeywhizLeader" },
      { pattern = "Control Keys:", hl = "KeywhizCtrl" },
      { pattern = "Alt Keys:", hl = "KeywhizAlt" },
      { pattern = "LSP:", hl = "KeywhizLSP" },
      { pattern = "★", hl = "KeywhizFavorite" },
      { pattern = "!", hl = "KeywhizConflict" },
      { pattern = "Movement", hl = "KeywhizCategoryMovement" },
      { pattern = "Editing", hl = "KeywhizCategoryEdit" },
      { pattern = "LSP", hl = "KeywhizCategoryLSP" },
      { pattern = "Windows", hl = "KeywhizCategoryWindow" },
    }

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
      for _, hl in ipairs(highlights) do
        if line:match(hl.pattern) then
          vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl.hl, i - 1, 0, -1)
        end
      end
    end
  end

  pickers
    .new({}, {
      prompt_title = "Keywhiz Themes",
      finder = finders.new_table({
        results = theme_list,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = require("telescope.previewers").new_buffer_previewer({
        define_preview = function(self, entry)
          local bufnr = self.state.bufnr
          local theme = entry.value.theme

          -- Create preview content
          local preview_content = {
            "Theme Preview: " .. entry.value.name,
            "",
            "Normal Text",
            "Leader Keys: <leader>ff",
            "Control Keys: <C-t>",
            "Alt Keys: <M-x>",
            "LSP: gd (Go to Definition)",
            "★ Favorite Item",
            "! Conflict Warning",
            "",
            "Categories:",
            "  Movement",
            "  Editing",
            "  LSP",
            "  Windows",
            "",
            "Press <CR> to apply theme",
            "Press <C-p> to preview",
          }

          -- Set preview content
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, preview_content)

          -- Apply theme highlights
          apply_highlights(bufnr, theme)
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        -- Preview theme on hover
        map("i", "<C-p>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            require("telescope._extensions.keywhiz").set_theme(selection.value.name, true)
          end
        end)

        -- Apply theme on selection
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if selection then
            require("telescope._extensions.keywhiz").set_theme(selection.value.name)
            actions.close(prompt_bufnr)
          end
        end)

        -- Reset preview on movement
        map("i", "<Up>", function()
          actions.move_selection_previous(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            require("telescope._extensions.keywhiz").set_theme(selection.value.name, true)
          end
        end)

        map("i", "<Down>", function()
          actions.move_selection_next(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            require("telescope._extensions.keywhiz").set_theme(selection.value.name, true)
          end
        end)

        return true
      end,
    })
    :find()
end

return M
