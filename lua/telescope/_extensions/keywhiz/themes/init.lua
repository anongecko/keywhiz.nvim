local M = {}

M.themes = {
  spacedust = require("telescope._extensions/keywhiz/themes/spacedust"),
  github = require("telescope._extensions/keywhiz/themes/github"),
  nord = require("telescope._extensions/keywhiz/themes/nord"),
  gruvbox = require("telescope._extensions/keywhiz/themes/gruvbox"),
  tokyo = require("telescope._extensions/keywhiz/themes/tokyo"),
  kanagawa = require("telescope._extensions/keywhiz/themes/kanagawa"),
}

-- Get theme colors
function M.get_theme(name)
  return M.themes[name] or M.themes.catppuccin
end

return M
