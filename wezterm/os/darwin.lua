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
  -- Send Cmd+P through to nvim as Ctrl+P (file finder)
  table.insert(config.keys, {
    key = 'p',
    mods = 'SUPER',
    action = wezterm.action.SendKey {
      key = 'p',
      mods = 'CTRL',
    },
  })
  -- Send Cmd+Shift+P through to nvim as Ctrl+Shift+P (command palette)
  table.insert(config.keys, {
    key = 'P',
    mods = 'SUPER|SHIFT',
    action = wezterm.action.SendKey {
      key = 'P',
      mods = 'CTRL|SHIFT',
    },
  })
  -- Send Cmd+Shift+F through to nvim as Ctrl+Shift+F (live grep search)
  table.insert(config.keys, {
    key = 'F',
    mods = 'SUPER|SHIFT',
    action = wezterm.action.SendKey {
      key = 'F',
      mods = 'CTRL|SHIFT',
    },
  })
  -- Cmd+Shift+O for project switcher (macOS uses Cmd instead of Ctrl)
  table.insert(config.keys, {
    key = 'o',
    mods = 'SUPER|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local projects = {}
      local home = wezterm.home_dir

      -- Scan ~/Projects directory
      for _, dir in ipairs(wezterm.glob(home .. '/Projects/*')) do
        local project_name = dir:match("([^/]+)$")
        table.insert(projects, {
          label = project_name,
          id = dir,
        })
      end

      -- Show project selection menu
      window:perform_action(
        wezterm.action.InputSelector {
          title = 'Select Project',
          choices = projects,
          fuzzy = true,
          action = wezterm.action_callback(function(_, inner_pane, id)
            if id then
              inner_pane:send_text('cd ' .. id .. '\nclear\nnvim\n')
            end
          end),
        },
        pane
      )
    end),
  })
end

return M
