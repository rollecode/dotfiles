-- Keybindings (shared across all platforms)

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
