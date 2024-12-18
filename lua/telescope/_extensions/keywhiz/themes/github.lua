return {
  name = "GitHub Dark",
  background = "dark",
  colors = {
    bg = "#24292e",
    bg_dark = "#1f2428",
    bg_highlight = "#2b3036",
    fg = "#c9d1d9",
    blue = "#58a6ff",
    cyan = "#79c0ff",
    green = "#3fb950",
    magenta = "#bc8cff",
    purple = "#8957e5",
    red = "#f85149",
    orange = "#db6d28",
    yellow = "#d29922",
    grey = "#6e7681",
  },
  groups = {
    KeywhizNormal = { fg = "fg", bg = "bg" },
    KeywhizBorder = { fg = "grey" },
    KeywhizTitle = { fg = "blue", bold = true },
    KeywhizLeader = { fg = "purple", bold = true },
    KeywhizCtrl = { fg = "red" },
    KeywhizAlt = { fg = "green" },
    KeywhizShift = { fg = "orange" },
    KeywhizSpecial = { fg = "magenta" },
    KeywhizLSP = { fg = "cyan", italic = true },
    KeywhizFavorite = { fg = "yellow", bold = true },
    KeywhizConflict = { fg = "red", bold = true },
  },
}
