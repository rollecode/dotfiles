-- Linux-specific WezTerm configuration

local M = {}

function M.apply(config)
  -- Linux-specific settings
  config.enable_wayland = true

  config.window_background_opacity = 0.60

  config.font_size = 12
  config.line_height = 1.15
  config.cell_width = 0.9

  config.window_padding = {
    left = '3.5cell',
    right = '3.5cell',
    top = '2.5cell',
    bottom = '1.5cell',
  }

  -- Terminal size
  config.initial_cols = 80
  config.initial_rows = 24

  -- Disable window decorations on Linux
  -- INTEGRATED_BUTTONS causes rendering glitches
  config.window_decorations = "NONE"
end

return M
