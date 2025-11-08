-- Linux-specific WezTerm configuration

local M = {}

function M.apply(config)
  -- Linux-specific settings
  config.enable_wayland = true

  -- Font size adjustment for Linux
  config.font_size = 12

  -- Font spacing for Linux
  config.line_height = 1.0
  config.cell_width = 0.85

  -- Disable window decorations on Linux (INTEGRATED_BUTTONS causes rendering glitches)
  config.window_decorations = "NONE"

  -- Add any other Linux-specific settings here
end

return M
