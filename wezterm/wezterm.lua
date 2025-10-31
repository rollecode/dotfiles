-- Rolle's WezTerm Configuration
-- Modular setup with OS-specific configurations

local wezterm = require 'wezterm'

-- Add current directory to Lua module search path
package.path = wezterm.config_dir .. '/?.lua;' .. wezterm.config_dir .. '/?/init.lua;' .. package.path

local config = {}

-- Use config builder if available
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- ========== SHARED CONFIGURATION (ALL PLATFORMS) ==========

-- Opacity/transparency configuration
config.window_background_opacity = 0.68

-- Font configuration - SF Mono for ligatures, Monaspace Krypton for non-ASCII
config.font = wezterm.font_with_fallback({
  { family = 'Liga SFMono Nerd Font', weight = 400 },
  { family = 'Monaspace Krypton NF',  weight = 400 }
})

-- Bold font configuration
config.bold_brightens_ansi_colors = true
config.font_rules = {
  {
    intensity = 'Bold',
    font = wezterm.font_with_fallback({
      { family = 'Liga SFMono Nerd Font', weight = 620 },
      { family = 'Monaspace Krypton NF',  weight = 620 }
    })
  }
}

-- Font spacing
config.line_height = 1.0
config.cell_width = 0.85

-- Window padding configuration
config.window_padding = {
  left = '4cell',
  right = '4cell',
  top = '2cell',
  bottom = '2cell',
}

-- Enable ligatures
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- Initial terminal size
config.initial_cols = 80
config.initial_rows = 28

-- Cursor configuration
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 400

-- Dracula color scheme
config.colors = {
  foreground = '#ffffff',
  background = '#0c0e14',
  cursor_bg = '#50fa7b',
  cursor_fg = '#0c0e14',
  cursor_border = '#50fa7b',
  selection_fg = '#ffffff',
  selection_bg = '#44475a',

  ansi = {
    '#000000', -- black
    '#ff5555', -- red
    '#50fa7b', -- green
    '#f1fa8c', -- yellow
    '#bd93f9', -- blue
    '#ff79c6', -- magenta
    '#8be9fd', -- cyan
    '#cccccc', -- white
  },
  brights = {
    '#555555',                         -- bright black
    '#ff5555',                         -- bright red
    '#50fa7b',                         -- bright green
    '#f1fa8c',                         -- bright yellow
    '#bd93f9',                         -- bright blue
    '#ff79c6',                         -- bright magenta
    '#8be9fd',                         -- bright cyan
    '#ffffff',                         -- bright white
  },
  split = 'rgba(255, 255, 255, 0.05)', -- Subtle split pane border
}

-- Disable tab bar completely
config.enable_tab_bar = false

-- Borderless window with integrated buttons
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- Pane border styling (subtle and transparent)
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.7,
}

-- Disable audible bell
config.audible_bell = "Disabled"

-- Scrollback buffer
config.scrollback_lines = 1000000

-- Disable Kitty keyboard protocol to prevent escape sequences in copied text
config.enable_kitty_keyboard = false

-- Disable all default mouse bindings so we have full control
config.disable_default_mouse_bindings = true

-- Keybindings
config.keys = {
  {
    key = 'r',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ReloadConfiguration,
  },
  -- Disable default Ctrl+Shift+P so nvim can use it
  {
    key = 'P',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DisableDefaultAssignment,
  },
  -- Disable default Ctrl+Shift+A so nvim can use it for Trouble
  {
    key = 'A',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DisableDefaultAssignment,
  },
  -- Disable default Ctrl+Shift+E so nvim can use it for neo-tree
  {
    key = 'E',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DisableDefaultAssignment,
  },
  -- Copy with Ctrl+Shift+C
  {
    key = 'C',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  -- Paste with Ctrl+Shift+V
  {
    key = 'V',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- Paste with Ctrl+V
  {
    key = 'V',
    mods = 'CTRL',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- Paste with Shift+Insert (traditional Linux paste)
  {
    key = 'Insert',
    mods = 'SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- Command palette (use Alt+K to avoid conflicting with nano Ctrl+K)
  {
    key = 'k',
    mods = 'ALT',
    action = wezterm.action.ActivateCommandPalette,
  },
  -- Disable default Ctrl+Shift+O so nvim can use it for project switcher
  {
    key = 'O',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DisableDefaultAssignment,
  },
  -- Split vertically (side by side) - removed Ctrl+D to keep default behavior
  -- Split horizontally (top and bottom) - removed Ctrl+Shift+D to keep default behavior
  -- Close current pane (use Alt+W to avoid conflicting with nano Ctrl+W)
  {
    key = 'w',
    mods = 'ALT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- Navigate between panes with Ctrl+Alt+Arrow
  {
    key = 'LeftArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- Resize panes with Ctrl+Shift+Arrow
  {
    key = 'LeftArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'RightArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 },
  },
  {
    key = 'UpArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 },
  },
  {
    key = 'DownArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 },
  },
}

-- ========== OS-SPECIFIC CONFIGURATION ==========

-- Detect OS and load OS-specific configuration
if wezterm.target_triple:find("linux") then
  require('os.linux').apply(config)
elseif wezterm.target_triple:find("darwin") then
  require('os.darwin').apply(config)
elseif wezterm.target_triple:find("windows") then
  require('os.windows').apply(config)
end

-- Load machine-specific config (optional, gitignored)
pcall(function()
  require('local').apply(config)
end)

-- ========== MOUSE BINDINGS (AFTER OS CONFIG) ==========
-- Set these last to prevent OS-specific configs from overriding

-- Custom mouse bindings
config.mouse_bindings = {
  -- Mouse wheel scrolling
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByCurrentEventWheelDelta,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByCurrentEventWheelDelta,
  },
  -- Single click + drag to select text
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.SelectTextAtMouseCursor 'Cell',
  },
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.ExtendSelectionToMouseCursor 'Cell',
  },
  -- Left mouse button UP does nothing (no copy)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.Nop,
  },
  -- Double click selects a word
  {
    event = { Down = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.SelectTextAtMouseCursor 'Word',
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.Nop,
  },
  -- Triple click selects a line
  {
    event = { Down = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.SelectTextAtMouseCursor 'Line',
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.Nop,
  },
  -- CTRL-Click opens hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.Nop,
  },
  -- Right-click: Show context menu
  {
    event = { Up = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ""

      local choices = {}

      if has_selection then
        table.insert(choices, { id = 'copy', label = '📋 Copy' })
        table.insert(choices, { id = 'search', label = '🔍 Search in browser' })
      end

      table.insert(choices, { id = 'split_h', label = '⬌ Split Horizontal' })
      table.insert(choices, { id = 'split_v', label = '⬍ Split Vertical' })

      window:perform_action(
        wezterm.action.InputSelector({
          title = '─── Context Menu ───',
          choices = choices,
          fuzzy = false,
          alphabet = '', -- Disable numbering
          action = wezterm.action_callback(function(inner_window, inner_pane, id, _)
            if not id then return end

            if id == 'copy' then
              inner_window:perform_action(wezterm.action.CopyTo('ClipboardAndPrimarySelection'), inner_pane)
              inner_window:perform_action(wezterm.action.ClearSelection, inner_pane)
            elseif id == 'search' then
              local selection = inner_window:get_selection_text_for_pane(inner_pane)
              -- URL encode the selection properly
              local encoded = selection:gsub("([^%w%-%.%_%~ ])", function(c)
                return string.format("%%%02X", string.byte(c))
              end):gsub(" ", "+")
              local url = 'https://www.google.com/search?q=' .. encoded
              -- Open in browser
              os.execute('xdg-open "' .. url .. '" &')
            elseif id == 'split_h' then
              inner_window:perform_action(wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }), inner_pane)
            elseif id == 'split_v' then
              inner_window:perform_action(wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }), inner_pane)
            end
          end),
        }),
        pane
      )
    end),
  },
  -- Middle-click paste from primary selection
  {
    event = { Up = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'PrimarySelection',
  },
}

-- ========== OS-SPECIFIC MOUSE BINDINGS ==========
-- Add platform-specific mouse bindings after the main table is created

if wezterm.target_triple:find("darwin") then
  -- macOS: CMD-Click opens hyperlinks (in addition to CTRL-Click)
  table.insert(config.mouse_bindings, {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = wezterm.action.OpenLinkAtMouseCursor,
  })
  table.insert(config.mouse_bindings, {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = wezterm.action.Nop,
  })
end

return config
