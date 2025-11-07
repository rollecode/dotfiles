-- luacheck: globals vim
-- Rolle's Neovim configuration
-- Modular setup with OS-specific configurations

-- Compatibility: use vim.uv (new) or vim.loop (old)
---@diagnostic disable-next-line: undefined-field
local uv = vim.uv or vim.loop

-- Set leader
vim.g.mapleader = " "

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
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

-- Apply custom variable colors (override orange with cyan/blue/purple)
vim.api.nvim_set_hl(0, '@variable', { fg = '#c678dd' })           -- bright purple
vim.api.nvim_set_hl(0, '@variable.builtin', { fg = '#bb9af7' })   -- purple
vim.api.nvim_set_hl(0, '@variable.parameter', { fg = '#e0af68' }) -- yellow
vim.api.nvim_set_hl(0, '@variable.member', { fg = '#73daca' })    -- teal
-- Bash/shell specific
vim.api.nvim_set_hl(0, '@variable.bash', { fg = '#c678dd' })      -- bright purple
vim.api.nvim_set_hl(0, '@constant.bash', { fg = '#c678dd' })      -- bright purple for CONSTANTS

-- Load shared configuration modules
require('shared.options')
require('shared.keymaps')
require('shared.functions')
require('shared.codestats') -- Code::Stats setup and tracking
require('shared.autocmds')

-- Detect and load OS-specific configuration
---@diagnostic disable-next-line: undefined-field
local os_name = uv.os_uname().sysname
local os_configs = {
  Linux = 'os.linux',
  Darwin = 'os.darwin', -- macOS
  Windows_NT = 'os.windows'
}

if os_configs[os_name] then
  require(os_configs[os_name])
end

-- Load machine-specific config (optional, gitignored)
pcall(require, 'local')
