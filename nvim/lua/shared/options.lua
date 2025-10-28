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
  else
    -- Always use OSC 52 for clipboard (works over SSH)
    local function paste()
      return {vim.fn.getreg('"'), vim.fn.getregtype('"')}
    end

    local function copy(lines, regtype)
      vim.fn.setreg('"', lines, regtype)
      -- OSC 52 sequence: copy to system clipboard
      local text = table.concat(lines, '\n')
      -- Send OSC 52 escape sequence
      local b64 = vim.base64.encode(text)
      io.write(string.format('\027]52;c;%s\007', b64))
    end

    vim.g.clipboard = {
      name = 'OSC52',
      copy = {['+'] = copy, ['*'] = copy},
      paste = {['+'] = paste, ['*'] = paste},
    }
  end
end

setup_clipboard()
