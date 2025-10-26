-- luacheck: globals vim
-- Rolle's Neovim Configuration
-- Modular setup with OS-specific configurations

-- Add luarocks path for code-stats.nvim
local rocks_path = vim.fn.expand("~/.local/share/nvim/rocks")
package.path = package.path .. ";" .. rocks_path .. "/share/lua/5.1/?.lua;" .. rocks_path .. "/share/lua/5.1/?/init.lua"
package.cpath = package.cpath .. ";" .. rocks_path .. "/lib/lua/5.1/?.so"
vim.opt.runtimepath:append(rocks_path .. "/lib/luarocks/rocks-5.1/code-stats.nvim/0.0.3-1")

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin-specific global settings (must be set before plugins load)
vim.g.blamer_enabled = 1
vim.g.blamer_delay = 0
vim.g.blamer_relative_time = 1

-- Load plugins
require("lazy").setup("shared.plugins")

-- Set colorscheme
vim.cmd.colorscheme "catppuccin-mocha"

-- Load shared configuration modules
require('shared.options')
require('shared.keymaps')
require('shared.functions')
require('shared.codestats')  -- Code::Stats setup and tracking
require('shared.autocmds')

-- Detect and load OS-specific configuration
local uv = vim.uv or vim.loop
local os_name = uv.os_uname().sysname
local os_configs = {
  Linux = 'os.linux',
  Darwin = 'os.darwin',  -- macOS
  Windows_NT = 'os.windows'
}

if os_configs[os_name] then
  require(os_configs[os_name])
end

-- Load machine-specific config (optional, gitignored)
pcall(require, 'local')
