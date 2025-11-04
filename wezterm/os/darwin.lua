-- macOS-specific WezTerm configuration

local M = {}

function M.apply(config)
  local wezterm = require 'wezterm'
  -- macOS-specific settings

  -- macOS background blur
  config.macos_window_background_blur = 60

  -- Opacity (less transparent than Linux)
  config.window_background_opacity = 0.70

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
    bottom = '1.5cell',
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
  -- Cmd+Shift+O: WezTerm project switcher (reads from cd-project.nvim.json)
  table.insert(config.keys, {
    key = 'O',
    mods = 'SUPER|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local home = wezterm.home_dir
      local projects_file = home .. '/.config/nvim/cd-project.nvim.json'

      -- Read and parse JSON file
      local success, projects_json = pcall(function()
        local f = io.open(projects_file, 'r')
        if not f then return nil end
        local content = f:read('*all')
        f:close()
        return wezterm.json_parse(content)
      end)

      if not success or not projects_json or #projects_json == 0 then
        window:toast_notification('WezTerm', 'No projects found in ' .. projects_file, nil, 4000)
        return
      end

      -- Build choices from projects
      local choices = {}
      for _, project in ipairs(projects_json) do
        table.insert(choices, {
          label = project.name or project.path:match("([^/]+)$"),
          id = project.path,
        })
      end

      -- Show project picker
      window:perform_action(
        wezterm.action.InputSelector {
          title = 'Open Project',
          choices = choices,
          fuzzy = true,
          action = wezterm.action_callback(function(_, inner_pane, id)
            if id then
              inner_pane:send_text('cd ' .. id .. '\nclear\nnvim .\n')
            end
          end),
        },
        pane
      )
    end),
  })
  -- Send Cmd+Shift+E through to nvim (neo-tree toggle)
  table.insert(config.keys, {
    key = 'E',
    mods = 'SUPER|SHIFT',
    action = wezterm.action.SendKey {
      key = 'E',
      mods = 'CTRL|SHIFT',
    },
  })
  -- Send Cmd+Shift+? through to nvim as Ctrl+? (Neovim AI helper)
  table.insert(config.keys, {
    key = '?',
    mods = 'SUPER|SHIFT',
    action = wezterm.action.SendKey {
      key = '?',
      mods = 'CTRL',
    },
  })

  -- Cmd+Shift+S: Prepare for screenshot (set opacity to 100% for 5 seconds)
  table.insert(config.keys, {
    key = 's',
    mods = 'SUPER|SHIFT',
    action = wezterm.action_callback(function(window, _pane)
      -- Set opacity to 100% for clean screenshot
      window:set_config_overrides({ window_background_opacity = 1.0 })
      window:toast_notification('WezTerm', 'Screenshot mode: 100% opacity for 5 seconds', nil, 2000)

      -- Restore original opacity after 5 seconds
      wezterm.time.call_after(5, function()
        window:set_config_overrides({ window_background_opacity = 0.70 })
      end)
    end),
  })
end

return M
