-- macOS-specific WezTerm configuration

local M = {}

function M.apply(config)
  local wezterm = require 'wezterm'
  -- macOS-specific settings

  -- macOS background blur
  config.macos_window_background_blur = 60

  -- Opacity (less transparent than Linux)
  config.window_background_opacity = 0.50

  -- Font configuration for macOS (heavier weight)
  config.font = wezterm.font_with_fallback({
    { family = 'Liga SFMono Nerd Font', weight = 500 },
    { family = 'Monaspace Krypton NF',  weight = 500 }
  })
  config.font_size = 14

  -- Font spacing optimized for 13pt
  config.line_height = 1.085
  config.cell_width = 0.87

  -- Window padding optimized for macOS
  config.window_padding = {
    left = '3cell',
    right = '3cell',
    top = '2.5cell',
    bottom = '0.8cell',
  }

  -- Terminal size
  config.initial_cols = 87
  config.initial_rows = 28

  -- macOS-specific keybindings
  table.insert(config.keys, {
    key = 'v',
    mods = 'SUPER',
    action = wezterm.action.PasteFrom 'Clipboard',
  })
  table.insert(config.keys, {
    key = 'c',
    mods = 'SUPER',
    action = wezterm.action.CopyTo 'Clipboard',
  })
  -- Send Cmd+A through to nvim as a key sequence it can recognize
  table.insert(config.keys, {
    key = 'a',
    mods = 'SUPER',
    action = wezterm.action.SendKey {
      key = 'a',
      mods = 'CTRL|SHIFT',
    },
  })
end

return M
