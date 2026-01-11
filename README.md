# Rolle's dotfiles

![Version](https://img.shields.io/badge/version-2.2.4-purple.svg?style=for-the-badge) ![bash](https://img.shields.io/badge/bash-%23121011.svg?style=for-the-badge&color=%23222222&logo=gnu-bash&logoColor=white) ![linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white) ![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white) ![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?style=for-the-badge&logo=neovim&logoColor=white) ![WezTerm](https://img.shields.io/badge/WezTerm-4E49EE?style=for-the-badge&logo=wezterm&logoColor=white)
  
Cross-platform configuration files for Neovim and WezTerm with OS-specific settings.

<img width="813" height="240" alt="image" src="https://github.com/user-attachments/assets/928941fa-fde7-4c05-b9e2-cc81bc1fe2f5" />

## Installation 

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ronilaukkarinen/dotfiles/master/install.sh)
```

## Features

🎯 **Modular structure** - Shared configs + OS-specific overrides<br>
🔐 **Secrets management** - API keys in gitignored files<br>
🌍 **Cross-platform** - Works on Linux, macOS, and Windows<br>
🎮 **Gamification & stats** - [Code::Stats](https://codestats.net/users/rolle) and [gamify](https://github.com/GrzegorzSzczepanek/gamify.nvim) with streak tracking<br>
🤖 **Claude Code integration** - Automatic XP tracking for AI-assisted coding

## Requirements

- [Neovim](https://neovim.io/) - 0.10+ required
- [WezTerm](https://wezfurlong.org/wezterm/) - Terminal emulator
- [Liga SFMono Nerd Font](https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized) - Ligaturized SF Mono with Nerd Font icons
- [Monaspace](https://monaspace.githubnext.com/) - Monaspace Krypton NF font
- [Claude Code](https://claude.ai/download) - AI-assisted coding with Code::Stats integration

## Manual installation

For selective updates or if you prefer manual setup:

### Clone the repository

```bash
git clone git@github.com:ronilaukkarinen/dotfiles.git ~/Projects/dotfiles
```

### Symlink configs (Linux/macOS)

```bash
# WezTerm
ln -sf ~/Projects/dotfiles/wezterm ~/.config/wezterm

# Neovim
ln -sf ~/Projects/dotfiles/nvim ~/.config/nvim

# Hammerspoon (macOS only)
ln -sf ~/Projects/dotfiles/hammerspoon ~/.hammerspoon
```

### Symlink configs (Windows - PowerShell as Admin)

```powershell
# Clone repository
git clone git@github.com:ronilaukkarinen/dotfiles.git $env:USERPROFILE\Projects\dotfiles

# WezTerm
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\wezterm" -Target "$env:USERPROFILE\Projects\dotfiles\wezterm" -Force

# Neovim
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\Local\nvim" -Target "$env:USERPROFILE\Projects\dotfiles\nvim" -Force
```

### Configure secrets

```bash
# Neovim
cp ~/Projects/dotfiles/nvim/lua/secrets.lua.example ~/Projects/dotfiles/nvim/lua/secrets.lua
nvim ~/Projects/dotfiles/nvim/lua/secrets.lua

# Claude Code
cp ~/Projects/dotfiles/claude-code/secrets.sh.example ~/Projects/dotfiles/claude-code/secrets.sh
nvim ~/Projects/dotfiles/claude-code/secrets.sh
```

Get your Code::Stats API key from https://codestats.net/my/machines

**With symlinks, any changes you make to your configs automatically update the repo!** Just commit and push when ready.

Linter and formatter notifications appear automatically when you open files - nvim-lint will warn you if a linter is missing for that specific file type.

## Claude code integration

Track your AI-assisted coding activity with Code::Stats automatically! Every time Claude Code writes or edits a file, you'll earn XP and see a yellow ASCII box notification in WezTerm (1 XP per line written by Claude).

The install script sets up the hook symlink automatically. You just need to configure `~/.claude/settings.json`:

### Configure Claude code hooks

Add the following to your `~/.claude/settings.json` (if you already have settings, just add the `hooks` section):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/codestats-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### How it works

The hook automatically:
- Detects file type from extension (JavaScript, Python, Markdown, Bash, etc.)
- Calculates XP based on characters written (1 XP = 1 character)
- Sends the XP to Code::Stats API after each file edit/write
- Supports all file types that Claude Code can edit

Now your AI-assisted coding will contribute to your Code::Stats profile!

### Auto-save conversations

Automatically save and archive all your Claude Code conversations with searchable markdown transcripts. This uses the [claude-conversation-saver](https://github.com/sirkitree/claude-conversation-saver) plugin wrapping the [conversation-logger](https://github.com/sirkitree/claude-conversation-saver) skill. Read more at [Jerad Bitner's blog post](https://jeradbitner.com/blog/claude-code-auto-save-conversations).

Run this command in Claude Code:

```
/plugin marketplace add https://github.com/sirkitree/claude-conversation-saver
```

Then restart Claude Code. The plugin will automatically save conversations after each response to `~/.claude/conversation-logs/` with markdown transcripts, JSONL raw data, and session metadata.

The plugin needs these tools (likely already installed):

- `git` - for cloning the skill
- `jq` - JSON processor for parsing data
- `python3` - for markdown conversion

Install missing dependencies:

Arch Linux:

```bash
sudo pacman -S git jq python
```

Debian/Ubuntu:

```bash
sudo apt install git jq python3
```

macOS:

```bash
brew install git jq python3
```

After installation, conversations are automatically saved. Use these slash commands:

- `/convo-search <query>` - search across all saved conversations
- `/convo-list` - list all saved conversations
- `/convo-recent` - show recent conversations

This ensures you never lose important conversations and can search through your entire Claude Code history!

### Setup on other machines

On any other machine where you use Claude Code, just run the install script:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ronilaukkarinen/dotfiles/master/install.sh)
```

Then configure your secrets and `~/.claude/settings.json` as instructed.

### Setup on remote servers

For remote servers where you use Claude Code via SSH, run the install script:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ronilaukkarinen/dotfiles/master/install.sh)
```

Or for manual Claude Code hook setup only:

```bash
# Clone dotfiles
git clone git@github.com:ronilaukkarinen/dotfiles.git ~/Projects/dotfiles

# Create secrets file with your API key
echo '#!/bin/bash
export CODESTATS_API_KEY="YOUR_API_KEY_HERE"' > ~/Projects/dotfiles/claude-code/secrets.sh
chmod +x ~/Projects/dotfiles/claude-code/secrets.sh

# Symlink the hook
mkdir -p ~/.claude/hooks
ln -sf ~/Projects/dotfiles/claude-code/codestats-hook.sh ~/.claude/hooks/codestats-hook.sh

# Add hooks to ~/.claude/settings.json on the server (see above)
```

## Linters

The install script asks which linters you want to activate. You can enable/disable individual linters for different languages. Each linter checks code quality and shows errors/warnings inline as you type.

### Available linters

- **phpcs** - PHP Code Sniffer for PHP files
- **stylelint** - CSS/SCSS linter
- **flake8** - Python linter
- **luacheck** - Lua linter
- **jsonlint** - JSON linter
- **eslint** - JavaScript linter

### Manual activation

To manually enable/disable linters after installation, edit `~/Projects/dotfiles/nvim/lua/local.lua`:

```lua
return {
    -- ... other settings ...

    -- Linters (set to true to enable, false to disable)
    enable_phpcs = true,      -- PHP linter
    enable_stylelint = true,  -- CSS/SCSS linter
    enable_flake8 = true,     -- Python linter
    enable_luacheck = true,   -- Lua linter
    enable_jsonlint = true,   -- JSON linter
    enable_eslint = true,     -- JavaScript linter
}
```

After editing, restart Neovim for changes to take effect.

### Installing linters

If a linter is enabled but not installed, nvim-lint will show a notification with installation instructions when you open a file of that type.

#### PHP (phpcs)

```bash
composer global require squizlabs/php_codesniffer
```

#### CSS/SCSS (stylelint)

```bash
npm install -g stylelint
```

#### Python (flake8)

```bash
pip install flake8
```

#### Lua (luacheck)

```bash
luarocks install luacheck
```

#### JSON (jsonlint)

```bash
npm install -g jsonlint
```

#### JavaScript (eslint)

```bash
npm install -g eslint
```

### Project-specific linters

For JavaScript/PHP projects, nvim-lint will automatically detect and use project-local linters:

- **JavaScript**: Uses `node_modules/.bin/eslint` if available in your project
- **PHP**: Uses `vendor/bin/phpcs` if available in your project

This ensures project-specific rules and configurations are respected.

## Remote server setup

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
- [lualine](https://github.com/nvim-lualine/lualine.nvim) - Status bar with Code::Stats integration
- [barbar](https://github.com/romgrk/barbar.nvim) - Buffer tabline with icons and animations
- [auto-session](https://github.com/rmagatti/auto-session) - Auto-save and auto-restore sessions per directory
- [cd-project.nvim](https://github.com/LintaoAmons/cd-project.nvim) - VSCode-like project manager
- [telescope](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [telescope-frecency](https://github.com/nvim-telescope/telescope-frecency.nvim) - Frecency algorithm for telescope
- [gamify](https://github.com/GrzegorzSzczepanek/gamify.nvim) - Gamify coding with achievements and streaks
- [gitsigns](https://github.com/lewis6991/gitsigns.nvim) - Git signs in gutter, inline blame, hunk actions
- [mini.files](https://github.com/echasnovski/mini.files) - Lightweight file explorer
- [which-key](https://github.com/folke/which-key.nvim) - Shows keybindings in popup
- [presence](https://github.com/andweeb/presence.nvim) - Discord Rich Presence
- [nvim-notify](https://github.com/rcarriga/nvim-notify) - Notification manager
- [nvim-lint](https://github.com/mfussenegger/nvim-lint) - Linting with contextual diagnostics
- [conform](https://github.com/stevearc/conform.nvim) - Auto-formatting on save
- [indentmini](https://github.com/nvimdev/indentmini.nvim) - Minimal indent guides
- [tiny-inline-diagnostic](https://github.com/rachartier/tiny-inline-diagnostic.nvim) - Inline diagnostic messages
- [trouble](https://github.com/folke/trouble.nvim) - Diagnostics panel
- [dropbar](https://github.com/Bekaboo/dropbar.nvim) - Context-aware breadcrumbs
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Better syntax highlighting with Tree-sitter
- [blink.cmp](https://github.com/Saghen/blink.cmp) - Completion plugin
- [minuet-ai](https://github.com/milanglacier/minuet-ai.nvim) - AI code completion with Ollama
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Lua utilities (includes custom Neovim AI helper)
- [Comment.nvim](https://github.com/numToStr/Comment.nvim) - Toggle comments
- [leap.nvim](https://github.com/ggandor/leap.nvim) - Jump to any location with search labels
- [hardtime](https://github.com/m4xshen/hardtime.nvim) - Learn better Vim motions
- [mason](https://github.com/williamboman/mason.nvim) - LSP server manager
- [mason-lspconfig](https://github.com/williamboman/mason-lspconfig.nvim) - Bridge between mason and lspconfig
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configuration

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

