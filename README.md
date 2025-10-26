# Rolle's dotfiles

![bash](https://img.shields.io/badge/bash-%23121011.svg?style=for-the-badge&color=%23222222&logo=gnu-bash&logoColor=white) ![linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white) ![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white) ![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?style=for-the-badge&logo=neovim&logoColor=white) ![WezTerm](https://img.shields.io/badge/WezTerm-4E49EE?style=for-the-badge&logo=wezterm&logoColor=white)
  
Cross-platform configuration files for Neovim and WezTerm with OS-specific settings.

<img width="813" height="240" alt="image" src="https://github.com/user-attachments/assets/928941fa-fde7-4c05-b9e2-cc81bc1fe2f5" />

## Features

🎯 **Modular structure** - Shared configs + OS-specific overrides<br>
🔐 **Secrets management** - API keys in gitignored files<br>
🌍 **Cross-platform** - Works on Linux, macOS, and Windows<br>
🎮 **Gamification & stats** - [Code::Stats](https://codestats.net/users/rolle) and [gamify](https://github.com/GrzegorzSzczepanek/gamify.nvim) with streak tracking

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

### Quick Setup (One-liners)

#### With Symlinks (Recommended)

Changes to configs automatically update the repo:

#### Linux/macOS
```bash
# WezTerm
ln -sf ~/Projects/dotfiles/wezterm ~/.config/wezterm

# Neovim
ln -sf ~/Projects/dotfiles/nvim ~/.config/nvim && cp ~/Projects/dotfiles/nvim/lua/secrets.lua.example ~/Projects/dotfiles/nvim/lua/secrets.lua
```

#### Windows (PowerShell as Admin)

```powershell
# WezTerm
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\wezterm" -Target "$env:USERPROFILE\Projects\dotfiles\wezterm" -Force

# Neovim
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\Local\nvim" -Target "$env:USERPROFILE\Projects\dotfiles\nvim" -Force; Copy-Item "$env:USERPROFILE\Projects\dotfiles\nvim\lua\secrets.lua.example" "$env:USERPROFILE\Projects\dotfiles\nvim\lua\secrets.lua"
```

#### Without Symlinks

Copy files directly (requires manual updates):

#### Linux/macOS

```bash
# WezTerm
cp -r ~/Projects/dotfiles/wezterm ~/.config/wezterm

# Neovim
cp -r ~/Projects/dotfiles/nvim ~/.config/nvim && cp ~/Projects/dotfiles/nvim/lua/secrets.lua.example ~/.config/nvim/lua/secrets.lua
```

#### Windows (PowerShell)

```powershell
# WezTerm
Copy-Item -Recurse -Force "$env:USERPROFILE\Projects\dotfiles\wezterm" "$env:USERPROFILE\.config\wezterm"

# Neovim
Copy-Item -Recurse -Force "$env:USERPROFILE\Projects\dotfiles\nvim" "$env:USERPROFILE\AppData\Local\nvim"; Copy-Item "$env:USERPROFILE\Projects\dotfiles\nvim\lua\secrets.lua.example" "$env:USERPROFILE\AppData\Local\nvim\lua\secrets.lua"
```

### Configure secrets

Edit `secrets.lua` and add your Code::Stats API key:

```bash
# With symlinks
nvim ~/Projects/dotfiles/nvim/lua/secrets.lua

# Without symlinks (Linux/macOS)
nvim ~/.config/nvim/lua/secrets.lua

# Without symlinks (Windows - use your preferred editor)
nvim ~/AppData/Local/nvim/lua/secrets.lua
```

**With symlinks, any changes you make to your configs automatically update the repo!** Just commit and push when ready.

Linter and formatter notifications appear automatically when you open files - nvim-lint will warn you if a linter is missing for that specific file type.

## Remote Server Setup

### Install Neovim (first time), oneliner

```bash
curl -L https://github.com/ronilaukkarinen/dotfiles/archive/refs/heads/master.tar.gz | tar xz && cp -r dotfiles-master/nvim ~/.config/ && rm -rf dotfiles-master && echo "code_stats_api_key = 'SFxxxx'\ncodestats_username = 'rolle'" > ~/.config/nvim/lua/secrets.lua
```

### Update Neovim, oneliner

```bash
curl -L https://github.com/ronilaukkarinen/dotfiles/archive/refs/heads/master.tar.gz | tar xz && cp -r dotfiles-master/nvim/* ~/.config/nvim/ && rm -rf dotfiles-master
```

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
- **PowerShell as default shell** - Opens with PowerShell (`powershell.exe`) by default
- **WSL Ubuntu 22.04** - Press `Ctrl+Shift+B` to spawn WSL Ubuntu in a split pane
- **Launch menu** - Access PowerShell, WSL Ubuntu 22.04, Git Bash, or CMD via the launcher (`Ctrl+K` → search "launcher")
- Adjusted keybindings where needed

#### Making "bash" command open WSL Ubuntu 22.04

To make typing `bash` in PowerShell open WSL Ubuntu 22.04, add this to your PowerShell profile:

```powershell
# Override bash command to use WSL Ubuntu 22.04
function bash {
    wsl -d Ubuntu-22.04
}
```

Profile location: `C:\Users\YourUsername\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

Create the file if it doesn't exist, then restart PowerShell or run `. $PROFILE` to apply changes.

## Installed plugins

- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [catppuccin](https://github.com/catppuccin/nvim) - Color scheme (Mocha variant)
- [oklch-color-picker](https://github.com/eero-lehtinen/oklch-color-picker.nvim) - OKLCH color picker with graphical interface
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
- [barbar](https://github.com/romgrk/barbar.nvim) - Buffer tabline with icons and animations
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

### WezTerm
- `Ctrl+Shift+O` - Project switcher
- `Ctrl+K` - Command palette
- `Ctrl+D` - Split pane vertically (side by side)
- `Ctrl+Shift+D` - Split pane horizontally (top/bottom)
- `Ctrl+Shift+B` - Spawn WSL Ubuntu 22.04 in split pane (Windows only)
- `Ctrl+W` - Close pane
- `Ctrl+Alt+Arrows` - Navigate panes
- `Ctrl+Shift+Arrows` - Resize panes
- `Ctrl+Shift+R` - Reload configuration

### Neovim
- `Ctrl+P` - Telescope frecency
- `Ctrl+Shift+P` - Command palette
- See individual plugin docs for more keybindings

## Syncing gamify data

To sync your gamify streak and statistics across machines:

### Install Syncthing

#### Linux

```bash
# Debian/Ubuntu
sudo apt install syncthing

# Arch Linux
sudo pacman -S syncthing
```

#### macOS

```bash
brew install syncthing
```

### Enable auto-start

#### Linux (systemd)

```bash
# Enable and start Syncthing service
systemctl --user enable syncthing.service
systemctl --user start syncthing.service
```

#### macOS

```bash
# Syncthing will auto-start after brew installation
brew services start syncthing
```

### Set up syncing

1. Open the web UI at `http://127.0.0.1:8384`
2. Set up GUI authentication (Settings → GUI → Set username and password)
3. Add a new folder pointing to `~/.local/share/nvim/gamify/` with Folder Label "nvim gamify"
4. In folder settings, go to Advanced:
   - Tick Ignore Permissions
   - Set Full Rescan Interval (s) to `300` (5 minutes for faster sync)
5. Share this folder with your other devices
6. Syncthing will keep your streaks in sync automatically

### Remote access via nginx reverse proxy (Linux only)

To access Syncthing web UI from outside your network:

#### Install nginx

```bash
# Debian/Ubuntu
sudo apt install nginx

# Arch Linux
sudo pacman -S nginx
```

#### Create nginx reverse proxy configuration

```bash
sudo tee /etc/nginx/sites-available/syncthing > /dev/null << 'EOF'
server {
    listen 0.0.0.0:8385;
    listen [::]:8385;
    server_name your-domain.example.com;

    location / {
        proxy_pass http://127.0.0.1:8384/;
        proxy_http_version 1.1;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;

        # by default nginx times out connections in one minute
        proxy_read_timeout 1d;
    }
}
EOF
```

Replace `your-domain.example.com` with your actual domain name.

#### Enable the nginx site

```bash
sudo ln -s /etc/nginx/sites-available/syncthing /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl start nginx
```

#### Configure router port forwarding

Set up port forwarding in your router:

- External port: `8385`
- Internal IP: Your server's local IP (e.g., `192.168.1.100`)
- Internal port: `8385`
- Protocol: `TCP`

#### Access Syncthing remotely

You can now access Syncthing from anywhere at `http://your-domain.example.com:8385/`

Make sure you have GUI authentication enabled (step 2 in "Set up syncing" above).

## Updates

### With Symlinks
Simply pull the latest changes:
```bash
cd ~/Projects/dotfiles && git pull
```
Reload WezTerm (`Ctrl+Shift+R`) and restart Neovim to apply changes.

### Without Symlinks

Pull and re-copy files:

#### Linux/macOS

```bash
cd ~/Projects/dotfiles && git pull && cp -r wezterm ~/.config/ && cp -r nvim ~/.config/
```

#### Windows (PowerShell)

```powershell
cd ~/Projects/dotfiles; git pull; Copy-Item -Recurse -Force wezterm "$env:USERPROFILE\.config\"; Copy-Item -Recurse -Force nvim "$env:USERPROFILE\AppData\Local\"
```

### .bashrc

My .bashrc changes depending on the system I'm on, but here are some useful lines to add.

```bash
# Add trailing slash when tab-completing directories
bind 'set mark-directories on'
bind 'set mark-symlinked-directories on'
```

