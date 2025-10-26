# Rolle's dotfiles

Cross-platform configuration files for Neovim and WezTerm with OS-specific settings.

## Features

- 🎯 Modular structure - Shared configs + OS-specific overrides
- 🔐 Secrets management - API keys in gitignored files
- 🌍 Cross-platform - Works on Linux, macOS, and Windows
- ✅ Health checks - Automatic dependency checking
- 📊 [Code::Stats](https://codestats.net/users/rolle) integration - Track your coding activity
- 🎮 Gamification - [Gamify plugin](https://github.com/GrzegorzSzczepanek/gamify.nvim) with streak tracking
- 🔄 Syncthing ready - Sync plugin data across machines

## Requirements

- [Neovim](https://neovim.io/) - 0.10+ required
- [WezTerm](https://wezfurlong.org/wezterm/) - Terminal emulator
- [Liga SFMono Nerd Font](https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized) - Ligaturized SF Mono with Nerd Font icons
- [Monaspace](https://monaspace.githubnext.com/) - Monaspace Krypton NF font

## Installation

### Clone the repository

```bash
git clone git@github.com:ronilaukkarinen/dotfiles.git ~/Projects/dotfiles
```

### Set up secrets

```bash
# Neovim secrets
cp ~/Projects/dotfiles/nvim/lua/secrets.lua.example ~/.config/nvim/lua/secrets.lua
# Edit and add your Code::Stats API key
nvim ~/.config/nvim/lua/secrets.lua
```

### Set up secrets and symlinks

```bash
# Copy secrets template and add your API keys
cp ~/Projects/dotfiles/nvim/lua/secrets.lua.example ~/Projects/dotfiles/nvim/lua/secrets.lua
nvim ~/Projects/dotfiles/nvim/lua/secrets.lua

# Create symlinks (configs will point directly to repo)
ln -sf ~/Projects/dotfiles/nvim ~/.config/nvim
ln -sf ~/Projects/dotfiles/wezterm ~/.config/wezterm
```

**With symlinks, any changes you make to your configs automatically update the repo!** Just commit and push when ready.

Linter and formatter notifications appear automatically when you open files - nvim-lint will warn you if a linter is missing for that specific file type.

## Platform-specific notes

### Linux

- Uses `/usr/bin/python3`
- nvm integration for Node.js
- Wayland clipboard workaround for WezTerm

### macOS

- Uses Homebrew Python: `/opt/homebrew/bin/python3`
- Background blur effects in WezTerm
- Optimized font rendering (weight 500, size 13pt)

### Windows

- Uses system Python
- Adjusted keybindings where needed

## Installed plugins

- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [catppuccin](https://github.com/catppuccin/nvim) - Color scheme (Mocha variant)
- [dashboard](https://github.com/nvimdev/dashboard-nvim) - Recent projects and files in start
- [lualine](https://github.com/nvim-lualine/lualine.nvim) - Status bar
- [persistence](https://github.com/folke/persistence.nvim) - Session management, automatically saves and restores nvim sessions
- [telescope](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [telescope-frecency](https://github.com/nvim-telescope/telescope-frecency.nvim) - Frecency algorithm for telescope
- [project.nvim](https://github.com/ahmedkhalf/project.nvim) - Project management
- [gamify](https://github.com/GrzegorzSzczepanek/gamify.nvim) - Gamify coding in nvim, achievements, streaks
- [gitsigns](https://github.com/lewis6991/gitsigns.nvim) - Git signs in gutter, inline blame, hunk actions
- [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) - File explorer
- [flash](https://github.com/folke/flash.nvim) - Navigate your code with search labels
- [which-key](https://github.com/folke/which-key.nvim) - Helps you remember your Neovim keymaps
- [minimap.vim](https://github.com/wfxr/minimap.vim) - Code minimap sidebar
- [presence](https://github.com/andweeb/presence.nvim) - Discord live presence
- [nvim-notify](https://github.com/rcarriga/nvim-notify) - Notifications
- [nvim-lint](https://github.com/mfussenegger/nvim-lint) - Lint code, see errors in the current file
- [conform](https://github.com/stevearc/conform.nvim) - Auto format your code
- [indentmini](https://github.com/nvimdev/indentmini.nvim) - Indent guides
- [tiny-inline-diagnostic](https://github.com/rachartier/tiny-inline-diagnostic.nvim) - Like ErrorLens, UI for displaying the linter errors
- [trouble](https://github.com/folke/trouble.nvim) - See errors across all files in the project
- [dropbar](https://github.com/Bekaboo/dropbar.nvim) - VSCode-like breadcrumbs for nvim
- [blink.cmp](https://github.com/Saghen/blink.cmp) - Completion for definitions
- [minuet-ai](https://github.com/milanglacier/minuet-ai.nvim) - AI code completion with Ollama
- [hardtime](https://github.com/m4xshen/hardtime.nvim) - Break bad habits, master Vim motions
- [mason](https://github.com/williamboman/mason.nvim) - LSP server manager
- [mason-lspconfig](https://github.com/williamboman/mason-lspconfig.nvim) - Bridge between mason and lspconfig
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configuration
- [code-stats.nvim](https://github.com/Freed-Wu/code-stats.nvim) - Code::Stats integration for tracking coding activity

## Custom features

- Auto-restore sessions
- Code::Stats XP in statusline
- Gamify streak tracking
- OS-specific configurations
- Contextual linter notifications (only for files you're editing)

## Keybindings

- `Ctrl+Shift+O` - Project switcher (WezTerm)
- `Ctrl+P` - Telescope frecency
- `Ctrl+Shift+P` - Command palette
- `Ctrl+D` - Split pane vertically (WezTerm)
- `Ctrl+Shift+D` - Split pane horizontally (WezTerm)
- `Ctrl+W` - Close pane (WezTerm)
- `Ctrl+Alt+Arrows` - Navigate panes (WezTerm)
- `Ctrl+Shift+Arrows` - Resize panes (WezTerm)

## Syncing gamify data

To sync your gamify streak and statistics across machines:

1. Install Syncthing on all machines
2. Set up a shared folder for `~/.local/share/nvim/gamify/`
3. Syncthing will keep your streaks in sync automatically

## Updates

```bash
cd ~/Projects/dotfiles
git pull
```

Then restart your terminal/Neovim or re-source configs.
