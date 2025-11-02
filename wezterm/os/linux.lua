-- Linux-specific WezTerm configuration

local M = {}

function M.apply(config)
  -- Linux-specific settings
  config.enable_wayland = true

  -- Font size adjustment for Linux
  config.font_size = 12

  -- Add any other Linux-specific settings here
end

return M
