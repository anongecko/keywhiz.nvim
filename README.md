
# 🪄 keywhiz.nvim

A  keybinding management system for Neovim that helps you discover, search, and manage all your keymaps through Telescope. Search and execute any keybinding from:
- Default Neovim commands
- Custom user mappings
- NvChad default mappings
- Plugin mappings
- Buffer-local mappings

## ✨ Features

### 🔍 Universal Search
- Search across ALL keybindings in your Neovim setup
- Fuzzy find any command or mapping
- Category-based filtering
- Smart context awareness

### 🎨 Rich Display
- Color-coded key combinations
- Clear command descriptions
- Source indicators (shows where each mapping comes from)
- Context information (buffer-local, mode-specific, etc.)

### 📂 Smart Categories
Quick access to categorized commands:
1. All Keymaps (`1`)
2. Movement Commands (`2`)
3. Editing Operations (`3`)
4. LSP Functions (`4`)
5. Window Management (`5`)
6. File Operations (`6`)
7. Plugin Commands (`7`)
8. Search History (`8`)
9. Favorites (`9`)

### ⚡ Power Features
- **Live Editing**: Modify keybindings on the fly
- **Favorites System**: Star your most-used commands
- **Usage History**: Track your command usage
- **Alternative Suggestions**: Discover better ways to do things
- **Command Preview**: See detailed information before execution

## 🚀 Installation

### Prerequisites
- Neovim >= 0.9.0
- telescope.nvim
- nvim-web-devicons (optional, for icons)

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "username/keywhiz.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  cmd = "Keymaps",
  keys = {
    { "<leader>sk", "<cmd>Telescope keywhiz<cr>", desc = "Search Keymaps" },
  },
  opts = {
    -- your configuration options
  }
}
```

## ⚙️ Configuration

```lua
require("telescope").setup({
  extensions = {
    keywhiz = {
      -- Appearance
      appearance = {
        layout_strategy = "horizontal",
        layout_config = {
          width = 0.95,
          height = 0.8,
          preview_width = 0.5,
        },
      },
      
      -- Features
      features = {
        show_context = true,       -- Show where mappings come from
        show_source = true,        -- Show source file/plugin
        show_alternatives = true,  -- Show alternative keymaps
        enable_edit = true,        -- Allow editing keymaps
        enable_preview = true,     -- Show detailed preview
      },
      
      -- History settings
      history = {
        max_entries = 100,
        save_to_disk = true,
      },
      
      -- Favorites settings
      favorites = {
        max_entries = 50,
        save_to_disk = true,
      },
    }
  }
})
```

## 🎯 Usage

### Basic Usage
- Press `<leader>sk` to open keymap search
- Type to fuzzy search through keybindings
- Use number keys `1-9` to switch categories
- Press `<CR>` to execute selected keymap
- Press `<C-f>` to toggle favorite
- Press `<C-e>` to edit keymap

### Customizing Keymaps
1. **Through the UI**:
   - Find the keymap you want to modify
   - Press `<C-e>` to open the edit interface
   - Modify the mode, keys, or description
   - Save changes with `<CR>`

2. **Programmatically**:
```lua
-- Register a new keymap
require("keywhiz").register_keymap({
  mode = "n",
  lhs = "<leader>x",
  desc = "My Custom Command",
  category = "custom",
  callback = function()
    -- your command here
  end
})

-- Add a custom category
require("keywhiz").add_category("mycategory", {
  patterns = { "pattern1", "pattern2" },
  keywords = { "keyword1", "keyword2" },
})
```
### Favorites Management
Add keybindings to favorites in multiple ways:
1. In the Telescope interface:
   - Press `<C-f>` while a keymap is selected
   - Press `s` in normal mode while a keymap is selected
2. From anywhere in Neovim:
   - Use `:KeymapFavorite` when cursor is on a key combination
3. Programmatically:
   ```lua
   require("keywhiz").add_favorite({
     mode = "n",
     lhs = "<leader>ff",
     desc = "Find files"
   })

### Advanced Filtering
Filter your searches using prefixes:
- `@tag` - Filter by tag (e.g., `@lsp`)
- `#context` - Filter by context (e.g., `#buffer`)
- `^source` - Filter by source (e.g., `^plugin`)
- `!mode` - Filter by mode (e.g., `!n` for normal mode)

## 🎮 Commands

| Command | Description |
|---------|-------------|
| `:Keymaps` | Open main interface |
| `:KeymapsMovement` | Search movement commands |
| `:KeymapsEditing` | Search editing commands |
| `:KeymapsLSP` | Search LSP commands |
| `:KeymapsWindows` | Search window commands |
| `:KeymapsFavorites` | View favorite commands |

## 🛠️ API

```lua
-- Show keymap search
require("keywhiz").show()

-- Add custom category
require("keywhiz").add_category(name, patterns)

-- Register manual keymap
require("keywhiz").register_keymap(opts)

-- Get all keymaps
require("keywhiz").get_keymaps()
```

## ⚠️ Current Status

This plugin is under active development. Features and APIs may change.

## 🤝 Contributing

Contributions are welcome! Please check the [Contributing Guide](CONTRIBUTING.md) for guidelines.

## 📜 License

MIT License - See [LICENSE](LICENSE) for more information.
