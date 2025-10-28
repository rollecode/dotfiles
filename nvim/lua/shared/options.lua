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

-- Clipboard configuration
if vim.fn.has('mac') == 1 then
  -- macOS: use system clipboard
  vim.opt.clipboard = 'unnamedplus'
else
  -- Linux: use OSC 52 for SSH clipboard sync
  local function copy(lines, _)
    local text = table.concat(lines, '\n')
    local b64 = vim.base64.encode(text)
    io.write(string.format('\027]52;c;%s\007', b64))
  end

  local function paste()
    return {vim.fn.getreg('"'), vim.fn.getregtype('"')}
  end

  vim.g.clipboard = {
    name = 'OSC52',
    copy = {['+'] = copy, ['*'] = copy},
    paste = {['+'] = paste, ['*'] = paste},
  }

  vim.opt.clipboard = 'unnamedplus'
end
