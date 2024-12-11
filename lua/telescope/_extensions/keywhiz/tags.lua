local M = {}
local config = require("telescope._extensions.keywhiz.config")

M.tag_definitions = {
  -- Mode-based tags
  mode_tags = {
    n = { name = "normal", icon = "N" },
    i = { name = "insert", icon = "I" },
    v = { name = "visual", icon = "V" },
    x = { name = "visual", icon = "V" },
    s = { name = "select", icon = "S" },
    c = { name = "command", icon = "C" },
    t = { name = "terminal", icon = "T" },
  },

  -- Feature tags
  feature_tags = {
    buffer = { icon = "󰓩 ", desc = "Buffer-local mapping" },
    expr = { icon = "󰘦 ", desc = "Expression mapping" },
    nowait = { icon = "󰓕 ", desc = "No wait mapping" },
    silent = { icon = "󰝟 ", desc = "Silent mapping" },
    script = { icon = "󰑷 ", desc = "Script mapping" },
  },
}

-- Generate tags for a keymap
function M.generate_tags(keymap)
  local tags = {}

  -- Add mode tag
  if keymap.mode and M.tag_definitions.mode_tags[keymap.mode] then
    table.insert(tags, {
      type = "mode",
      name = M.tag_definitions.mode_tags[keymap.mode].name,
      icon = M.tag_definitions.mode_tags[keymap.mode].icon,
    })
  end

  -- Add feature tags
  for feature, tag_info in pairs(M.tag_definitions.feature_tags) do
    if keymap[feature] then
      table.insert(tags, {
        type = "feature",
        name = feature,
        icon = tag_info.icon,
        desc = tag_info.desc,
      })
    end
  end

  -- Add source tag
  local source = require("telescope._extensions.keywhiz.utils").get_keymap_source(keymap)
  table.insert(tags, {
    type = "source",
    name = source,
    icon = config.get_icon(source),
  })

  return tags
end

-- Format tags for display
function M.format_tags(tags)
  local formatted = {}
  for _, tag in ipairs(tags) do
    table.insert(formatted, string.format("%s %s", tag.icon, tag.name))
  end
  return table.concat(formatted, " ")
end

-- Filter keymaps by tag
function M.filter_by_tag(keymaps, tag_filter)
  return vim.tbl_filter(function(keymap)
    local tags = M.generate_tags(keymap)
    for _, tag in ipairs(tags) do
      if tag.name:lower():match(tag_filter:lower()) then
        return true
      end
    end
    return false
  end, keymaps)
end

return M
