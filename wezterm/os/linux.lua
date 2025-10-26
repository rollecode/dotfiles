-- Linux-specific WezTerm configuration

local M = {}

function M.apply(config)
  -- Linux-specific settings

  -- Workaround for Wayland/Hyprland clipboard issues
  -- WezTerm's Wayland clipboard is broken, force X11 backend
  config.enable_wayland = false

  -- Font size adjustment for Linux
  config.font_size = 12

  -- Add any other Linux-specific settings here
end

return M
