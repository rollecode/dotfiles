-- Windows-specific WezTerm configuration

local M = {}

function M.apply(config)
  -- Windows-specific settings

  -- Font size adjustment for Windows
  config.font_size = 11

  -- Windows doesn't need Wayland workaround
  -- config.enable_wayland is not relevant on Windows

  -- Add any other Windows-specific settings here
  -- Example: config.default_prog = { 'pwsh.exe', '-NoLogo' }
end

return M
