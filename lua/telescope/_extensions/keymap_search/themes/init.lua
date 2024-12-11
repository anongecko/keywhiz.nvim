local M = {}

M.themes = {
  catppuccin = require("telescope._extensions/keymap_search/themes/catppuccin"),
  spacedust = require("telescope._extensions/keymap_search/themes/spacedust"),
  github = require("telescope._extensions/keymap_search/themes/github"),
  nord = require("telescope._extensions/keymap_search/themes/nord"),
  gruvbox = require("telescope._extensions/keymap_search/themes/gruvbox"),
  tokyo = require("telescope._extensions/keymap_search/themes/tokyo"),
  kanagawa = require("telescope._extensions/keymap_search/themes/kanagawa"),
}

-- Get theme colors
function M.get_theme(name)
  return M.themes[name] or M.themes.catppuccin
end

return M
