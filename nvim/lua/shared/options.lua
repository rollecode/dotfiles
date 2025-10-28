-- Basic Neovim options (shared across all platforms)

vim.opt.number = true                   -- Show line numbers
vim.opt.relativenumber = true           -- Show relative line numbers
vim.opt.cursorline = true               -- Highlight current line
vim.opt.mouse = 'a'                     -- Enable mouse support
vim.opt.ignorecase = true               -- Case insensitive search
vim.opt.smartcase = true                -- Unless you use capital letters
vim.opt.expandtab = true                -- Use spaces instead of tabs
vim.opt.shiftwidth = 2                  -- Indent by 2 spaces
vim.opt.tabstop = 2                     -- Tab = 2 spaces
vim.opt.paste = false                   -- Make sure paste mode is off

-- Clipboard setup with OSC 52 support for remote servers
local function setup_clipboard()
  -- Check if we have a clipboard provider (xclip, wl-clipboard, etc.)
  local has_provider = vim.fn.executable('xclip') == 1
    or vim.fn.executable('xsel') == 1
    or vim.fn.executable('wl-copy') == 1
    or vim.fn.executable('pbcopy') == 1

  if has_provider then
    -- Use system clipboard if available
    vim.opt.clipboard = 'unnamedplus'
  elseif os.getenv('SSH_CONNECTION') then
    -- On SSH, use OSC 52 to copy to local clipboard
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      },
    }
  end
end

setup_clipboard()
