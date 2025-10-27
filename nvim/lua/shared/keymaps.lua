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

-- Select all keybindings
if vim.fn.has('mac') == 1 then
  -- macOS: Cmd+A for select all (WezTerm translates to Ctrl+Shift+A)
  vim.keymap.set('n', '<C-S-a>', 'ggVG', { desc = 'Select all' })
  vim.keymap.set('v', '<C-S-a>', '<Esc>ggVG', { desc = 'Select all' })
  vim.keymap.set('i', '<C-S-a>', '<Esc>ggVG', { desc = 'Select all' })
  -- macOS: Keep Ctrl+A for beginning of line
  vim.keymap.set('i', '<C-a>', '<C-o>^', { desc = 'Go to beginning of line' })
  vim.keymap.set('n', '<C-a>', '^', { desc = 'Go to beginning of line' })
else
  -- Linux/Windows: Ctrl+A for select all
  vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select all' })
  vim.keymap.set('v', '<C-a>', '<Esc>ggVG', { desc = 'Select all' })
  vim.keymap.set('i', '<C-a>', '<Esc>ggVG', { desc = 'Select all' })
end
-- Ctrl+E for end of line (all platforms)
vim.keymap.set('i', '<C-e>', '<C-o>$', { desc = 'Go to end of line' })
vim.keymap.set('n', '<C-e>', '$', { desc = 'Go to end of line' })

-- Tab/Shift+Tab for indenting
vim.keymap.set('v', '<Tab>', '>gv', { desc = 'Indent and reselect' })
vim.keymap.set('v', '<S-Tab>', '<gv', { desc = 'Dedent and reselect' })
vim.keymap.set('n', '<Tab>', '>>', { desc = 'Indent line' })
vim.keymap.set('n', '<S-Tab>', '<<', { desc = 'Dedent line' })

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
vim.keymap.set('n', '<A-s-c>', '<Cmd>BufferCloseAllButCurrentOrPinned<CR>',
  { silent = true, desc = 'Close all but current/pinned' })

-- Buffer picking
vim.keymap.set('n', '<C-s>', '<Cmd>BufferPick<CR>', { silent = true, desc = 'Pick buffer' })

-- Help
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
