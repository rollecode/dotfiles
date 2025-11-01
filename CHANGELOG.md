### 2.0.6: 2025-11-01

* Add cross-platform desktop notifications to Code::Stats hook (Linux/macOS, safe for headless systems)
* Add automatic claude-conversation-saver plugin installation in install.sh for auto-archiving all conversations to markdown
* Add Super+Shift+C keybind to center windows in Hyprland
* Set Hyprland border_size to 1 with low opacity for subtle borders
* Reduce extend_border_grab_area from 25 to 10 pixels
* Enable no_hardware_cursors in Hyprland for proper cursor shape changes
* Add mouse_move_enables_dpms and key_press_enables_dpms to Hyprland

### 2.0.5: 2025-10-31

* Add CodeCompanion AI chat plugin for asking Neovim questions with <Space>nv hotkey (uses OpenRouter auto-router)
* Add "Open Link" and "Open in Incognito" options to WezTerm right-click context menu for URLs (incognito Linux-only, uses chromium)
* Add automatic URL detection and selection on right-click in WezTerm
* Add selected URL/text preview as first item in WezTerm right-click context menu
* Improve URL detection to recognize domains without protocol (example.com, github.io, etc.)
* Fix right-click menu losing selection by preserving existing selection before showing menu
* Add auto-restart capability to clipboard-notify.sh with systemd service integration
* Move clipboard-notify from hyprland.conf exec-once to systemd service for better reliability
* Add documentation for auto-saving Claude Code conversations with claude-conversation-saver plugin
* Add individual linter activation prompts in install.sh for phpcs, stylelint, flake8, luacheck, jsonlint, and eslint
* Add linter feature flags to local.lua configuration file
* Make nvim-lint conditionally enable linters based on flags in local.lua
* Add comprehensive linter documentation to README with manual activation instructions and installation commands
* Document project-specific linter detection for ESLint and phpcs
* Fix Ctrl+W and Ctrl+K not working in nano on SSH servers by changing WezTerm shortcuts to Alt+W and Alt+K
* Fix Ctrl+P to search all files in project instead of only recent files
* Replace heavy neo-tree with lightweight mini.files file explorer
* Fix phpcs and eslint to always use project-local vendor/bin or node_modules/.bin executables when available
* Fix phpcs to automatically detect and use phpcs.xml or phpcs.xml.dist from project root
* Fix linters to set correct working directory for project-specific configurations
* Fix nvim-lint invalid args error by using directory-change wrapper instead of modifying linter configs
* Fix unused local variable warning in darwin.lua by prefixing with underscore
* Add Super+Shift+C keybind to center windows on current workspace in Hyprland (fixes windows appearing outside screen)

### 2.0.4: 2025-10-30

* Add LSP (Language Server Protocol) as optional feature with explanation in install.sh
* Make Mason and LSP plugins optional with enable_lsp flag (defaults to enabled)
* Install Node.js via nvm when LSP enabled (no sudo required, per-user installation)
* Explain LSP features: autocomplete, go-to-definition, error checking, hover docs
* Show LSP requirements during install: Node.js/npm (~100MB), language servers (~50-200MB)
* Add leap.nvim for quick motion jumping (s/S to jump forward/backward)
* Replace broken session plugins with auto-session + cd-project.nvim for VSCode Project Manager workflow
* SaveProject command saves current directory to projects (prompts for optional name)
* OpenProject/Cmd+Shift+O in nvim opens saved projects picker to browse and switch
* Cmd+Shift+O in WezTerm shows project menu reading from cd-project.nvim.json (works even outside nvim)
* Sessions auto-save on exit and restore when switching projects (no empty buffer tabs)
* Fix all Cmd+Shift keybindings on macOS (E for neo-tree, O for projects) - match WezTerm Ctrl translations
* Auto-refresh neo-tree when switching projects via cd-project hook
* Disable Kitty keyboard protocol in WezTerm to prevent escape sequences in copied text
* Configure dashboard to show recent projects with hyper theme
* Add Cmd+Shift+S to prepare for screenshots (sets opacity to 100% for 5 seconds, macOS only)
* Projects stored in ~/.config/nvim/cd-project.nvim.json (manually editable)

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
