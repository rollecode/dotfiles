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
  config.font_size = 13

  -- Font spacing optimized for 13pt
  config.line_height = 1.077
  config.cell_width = 0.87

  -- Window padding optimized for macOS
  config.window_padding = {
    left = '3cell',
    right = '3cell',
    top = '3cell',
    bottom = '0.5cell',
  }

  -- Terminal size
  config.initial_cols = 82
  config.initial_rows = 26
end

return M
