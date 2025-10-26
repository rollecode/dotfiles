-- luacheck: globals vim
-- Keybindings (shared across all platforms)

-- OS-specific modifier key (Cmd on macOS, Ctrl elsewhere)
local mod = vim.fn.has('mac') == 1 and 'D' or 'C'

-- File tree toggle (Ctrl+Shift+E or Cmd+Shift+E on macOS)
vim.keymap.set('n', '<' .. mod .. '-S-e>', function()
  vim.cmd('Neotree toggle')
end, { silent = true, desc = 'Toggle file tree' })

-- Trouble toggle (Ctrl+Shift+A or Cmd+Shift+A on macOS)
vim.keymap.set('n', '<' .. mod .. '-S-a>', function()
  require("trouble").toggle("diagnostics")
end, { silent = true, desc = 'Toggle diagnostics panel' })

-- Ctrl+A / Ctrl+E for beginning/end of line (like nano/bash)
vim.keymap.set('i', '<C-a>', '<C-o>^', { desc = 'Go to beginning of line' })
vim.keymap.set('i', '<C-e>', '<C-o>$', { desc = 'Go to end of line' })
vim.keymap.set('n', '<C-a>', '^', { desc = 'Go to beginning of line' })
vim.keymap.set('n', '<C-e>', '$', { desc = 'Go to end of line' })

-- Diagnostic navigation
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end,
  { silent = true, desc = 'Next diagnostic' })
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end,
  { silent = true, desc = 'Previous diagnostic' })
vim.keymap.set('n', ']e', function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { silent = true, desc = 'Next error' })
vim.keymap.set('n', '[e', function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { silent = true, desc = 'Previous error' })

-- VSCode-like keybindings for Telescope
vim.keymap.set('n', '<C-p>', function()
  require('telescope').extensions.frecency.frecency(require('telescope.themes').get_dropdown({
    previewer = false,
    sorting_strategy = 'ascending',
    layout_config = {
      width = 0.8,
      height = 0.6,
      anchor = 'N',
      anchor_padding = 0,
      prompt_position = 'top',
    },
  }))
end, { silent = true, desc = 'Find Files (Recent)' })

vim.keymap.set('n', '<C-S-p>', function()
  require('telescope.builtin').commands(require('telescope.themes').get_dropdown({
    previewer = false,
    sorting_strategy = 'ascending',
    layout_config = {
      width = 0.8,
      height = 0.6,
      anchor = 'N',
      anchor_padding = 0,
      prompt_position = 'top',
    },
  }))
end, { silent = true, desc = 'Command Palette' })

-- Barbar buffer navigation
vim.keymap.set('n', '<C-t>', '<Cmd>enew<CR>', { silent = true, desc = 'New tab' })
vim.keymap.set('n', '<A-,>', '<Cmd>BufferPrevious<CR>', { silent = true, desc = 'Previous buffer' })
vim.keymap.set('n', '<A-.>', '<Cmd>BufferNext<CR>', { silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', { silent = true, desc = 'Move buffer left' })
vim.keymap.set('n', '<A->>', '<Cmd>BufferMoveNext<CR>', { silent = true, desc = 'Move buffer right' })

-- Jump to buffers 1-9
vim.keymap.set('n', '<A-1>', '<Cmd>BufferGoto 1<CR>', { silent = true, desc = 'Go to buffer 1' })
vim.keymap.set('n', '<A-2>', '<Cmd>BufferGoto 2<CR>', { silent = true, desc = 'Go to buffer 2' })
vim.keymap.set('n', '<A-3>', '<Cmd>BufferGoto 3<CR>', { silent = true, desc = 'Go to buffer 3' })
vim.keymap.set('n', '<A-4>', '<Cmd>BufferGoto 4<CR>', { silent = true, desc = 'Go to buffer 4' })
vim.keymap.set('n', '<A-5>', '<Cmd>BufferGoto 5<CR>', { silent = true, desc = 'Go to buffer 5' })
vim.keymap.set('n', '<A-6>', '<Cmd>BufferGoto 6<CR>', { silent = true, desc = 'Go to buffer 6' })
vim.keymap.set('n', '<A-7>', '<Cmd>BufferGoto 7<CR>', { silent = true, desc = 'Go to buffer 7' })
vim.keymap.set('n', '<A-8>', '<Cmd>BufferGoto 8<CR>', { silent = true, desc = 'Go to buffer 8' })
vim.keymap.set('n', '<A-9>', '<Cmd>BufferGoto 9<CR>', { silent = true, desc = 'Go to buffer 9' })
vim.keymap.set('n', '<A-0>', '<Cmd>BufferLast<CR>', { silent = true, desc = 'Go to last buffer' })

-- Buffer management
vim.keymap.set('n', '<A-c>', '<Cmd>BufferClose<CR>', { silent = true, desc = 'Close buffer' })
vim.keymap.set('n', '<A-p>', '<Cmd>BufferPin<CR>', { silent = true, desc = 'Pin/unpin buffer' })
vim.keymap.set('n', '<A-s-c>', '<Cmd>BufferCloseAllButCurrentOrPinned<CR>', { silent = true, desc = 'Close all but current/pinned' })

-- Buffer picking
vim.keymap.set('n', '<C-s>', '<Cmd>BufferPick<CR>', { silent = true, desc = 'Pick buffer' })
