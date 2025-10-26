-- Windows-specific WezTerm configuration

local wezterm = require 'wezterm'
local M = {}

function M.apply(config)
  -- Windows-specific settings

  -- Font size adjustment for Windows
  config.font_size = 11

  -- Set PowerShell as default shell
  config.default_prog = { 'powershell.exe', '-NoLogo' }

  -- Launch menu with multiple shell options
  config.launch_menu = {
    {
      label = 'PowerShell',
      args = { 'powershell.exe', '-NoLogo' },
    },
    {
      label = 'WSL Ubuntu 22.04',
      args = { 'wsl.exe', '-d', 'Ubuntu-22.04' },
    },
    {
      label = 'Git Bash',
      args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l' },
    },
    {
      label = 'Command Prompt',
      args = { 'cmd.exe' },
    },
  }

  -- Add keybinding to quickly spawn WSL Ubuntu 22.04 in a new pane
  table.insert(config.keys, {
    key = 'b',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitHorizontal {
      args = { 'wsl.exe', '-d', 'Ubuntu-22.04' },
    },
  })
end

return M
