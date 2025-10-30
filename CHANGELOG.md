### 2.0.4: 2025-10-30

* Add LSP (Language Server Protocol) as optional feature with explanation in install.sh
* Make Mason and LSP plugins optional with enable_lsp flag (defaults to enabled)
* Install Node.js via nvm when LSP enabled (no sudo required, per-user installation)
* Explain LSP features: autocomplete, go-to-definition, error checking, hover docs
* Show LSP requirements during install: Node.js/npm (~100MB), language servers (~50-200MB)
* Add leap.nvim for quick motion jumping (s/S to jump forward/backward)
* Remove SaveProject command - neovim-project auto-saves sessions when you work in any directory

### 2.0.3: 2025-10-29

* Add optional feature flags system with install.sh prompts for Ollama AI, Discord Rich Presence, and Gamify plugin
* Create lua/local.lua (gitignored) with machine-specific feature flags
* Make plugins conditionally load based on local.lua configuration (backward compatible - defaults to enabled)
* Make install.sh idempotent with prompts before backing up configs (WezTerm, Neovim, Hammerspoon), building/upgrading Neovim, and installing Git
* Add automatic Neovim version detection and upgrade to latest release (0.10+) in install.sh
* Build Neovim from source on Ubuntu/Debian to avoid GLIBC compatibility issues
* Use pre-built binaries for Fedora/RHEL/CentOS (newer GLIBC)
* Change install.sh to use HTTPS for git clone instead of SSH for better remote server compatibility
* Add Comment.nvim plugin with Cmd+Shift+7 (macOS) and Ctrl+Shift+7 (Linux/Windows) keybindings for toggling comments
* Add Hammerspoon configuration for macOS with Cmd+Option+Left/Right Mouse drag for window move/resize (Hyprland-style)
* Use canvas preview for smooth resizing (SkyRocket.spoon approach), Cmd+Option+Click without drag passes through to apps
* Remove Ctrl+D and Ctrl+Shift+D WezTerm split keybindings to restore default terminal behavior (close/terminate)
* Fix lualine always showing (independent of gamify), CodeStats XP shown even when gamify disabled, better error handling
* Add backup of local.lua when re-running install.sh to preserve settings
* Add version badge to README.md
* Make install.sh explicitly state which existing config files are found and preserved (not overwritten)
* Fix plugins not loading when optional features disabled (filter out nil values from plugin table)
* Fix project switcher not working on macOS (add Cmd+Shift+O keybinding)
* Fix Cmd+P (file finder) and Cmd+Shift+P (command palette) not working in nvim on macOS
* Add Cmd+Shift+F for live grep text search across all files in project
* Add ripgrep installation to install.sh (required for Telescope live_grep)
* Fix nvim-lint ESLint to search from file location upward, use project-local installation with proper working directory for node_modules resolution
* Fix ESLint notifications showing for non-JavaScript files (only run for JS/TS files)
* Add phpcs project-local configuration (searches for vendor/bin/phpcs, auto-detects phpcs.xml and composer.json rules)
* Disable TypeScript LSP diagnostics (use ESLint for JavaScript/TypeScript linting instead)
* Replace persistence.nvim and project.nvim with neovim-project (VSCode Project Manager-like experience)
* Remove WezTerm project switcher menu, pass Cmd+Shift+O to nvim for project management
* Configure neovim-project to only show manually saved projects (no auto-discovery)
* Add :SaveProject command (accessible via Cmd+Shift+P command palette) to save current directory to projects
* Add LSP keybindings: gd (go-to-definition), K (hover), Ctrl+Click (go-to-definition), gr (references), etc.
* Fix neo-tree to not create state files in project directories
* Fix missing TSConfig fields in nvim-treesitter configuration (sync_install, ignore_install, modules)
* Fix Claude Code XP hook to work globally from any directory (use ~/.claude/settings.json instead of settings.local.json)

### 2.0.2: 2025-10-27

* Add nvim-treesitter plugin for better syntax highlighting and code understanding with auto-parser directory creation
* Add Cmd+A for select all in nvim on macOS (keeps Ctrl+A for beginning of line)
* Add Ctrl+A for select all in nvim on Linux/Windows
* Add Tab/Shift+Tab for indenting/dedenting in nvim (all platforms)
* Add Cmd+Click to open URLs in default browser on macOS (WezTerm)
* Enable cursorline in nvim to highlight current line
* Add Claude Code integration with automatic Code::Stats XP tracking via hooks
* Add claude-code directory with codestats-hook.sh and secrets management
* Add XP logging to ~/.claude/codestats-hook.log with timestamps
* Add yellow ASCII box WezTerm overlay notifications showing XP (1 XP per line written by Claude)
* Add simple code-stats implementation for nvim without external dependencies
* Add Cmd+V paste and Cmd+C copy keybindings for macOS in wezterm
* Add Telescope search keymaps (<leader>s prefix for search operations)
* Fix gamify streak recalculation on nvim startup (handles Syncthing sync and DST transitions)
* Set leader key to space in nvim
* Increase bottom padding in wezterm for macOS (0.5cell → 1.5cell)
* Update .gitignore to exclude claude-code/secrets.sh
* Update starship.toml, show full path

### 2.0.1: 2025-10-26

* Add hyprland config
* Add barbar for nvim with custom styling (dim grey background, purple bottom border for active tab)
* Configure barbar to auto-hide when only one buffer is open
* Add Ctrl+T keybinding to open new tab
* Remove minimap plugin (wfxr/minimap.vim)
* Add neo-tree as default file explorer
* Add oklch-color-picker plugin for color picking
* Fix Code::Stats integration (custom XP submission workaround for broken plugin)
* Add Code::Stats XP display in lualine statusline with yellow color
* Fix CTRL + SHIFT + E (toggle neo-tree) and CTRL + SHIFT + A (toggle Trouble diagnostics) keybindings
* Configure WezTerm to pass through Ctrl+Shift+A and Ctrl+Shift+E to Neovim
* Set Trouble and neo-tree to load on startup (not lazy-loaded)
* Add luacheck compliance to keymaps configuration
* Remove nodeadkeys (too used to Mac's tilde with space)
* Update Hyprland config to use WezTerm instead of Ghostty (terminal variable, IRC autostart, restore-layout.sh)
* Disable hyprsession in Hyprland config
* Simplify connect-irc.sh script (remove manual window positioning)
* Remove redundant launch-ssh-tmux.sh script
* Add bash tab completion with trailing slashes for directories

### 2.0.0: 2025-10-26

* Revamp dotfiles after years of hiatus
* Release directly 2.0.0
* Open CHANGELOG.md
* Release os-specific wezterm and nvim settings
