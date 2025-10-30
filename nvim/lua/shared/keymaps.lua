-- luacheck: globals vim
-- Keybindings (shared across all platforms)

-- OS-specific modifier key (Cmd on macOS, Ctrl elsewhere)
local mod = vim.fn.has('mac') == 1 and 'D' or 'C'

-- Copy with Ctrl+C in visual mode (Linux only - macOS uses WezTerm's Cmd+C)
if vim.fn.has('mac') ~= 1 then
  vim.keymap.set('v', '<C-c>', '"+y', { silent = true, desc = 'Copy to clipboard' })
  vim.keymap.set('v', '<C-S-c>', '"+y', { silent = true, desc = 'Copy to clipboard' })
end

-- File tree toggle (Ctrl+Shift+E or Cmd+Shift+E on macOS)
vim.keymap.set('n', '<' .. mod .. '-S-e>', function()
  vim.cmd('Neotree toggle')
end, { silent = true, desc = 'Toggle file tree' })

-- Trouble toggle (Ctrl+Shift+A or Cmd+Shift+A on macOS)
vim.keymap.set('n', '<' .. mod .. '-S-a>', function()
  local ok, trouble = pcall(require, "trouble")
  if ok then
    trouble.toggle("diagnostics")
  else
    vim.notify("Trouble plugin is not loaded", vim.log.levels.WARN)
  end
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

-- Comment/uncomment line (Cmd+Shift+7 on macOS, Ctrl+Shift+7 elsewhere)
vim.keymap.set('n', '<' .. mod .. '-S-7>', function()
  local ok, comment_api = pcall(require, 'Comment.api')
  if ok then
    comment_api.toggle.linewise.current()
  end
end, { silent = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<' .. mod .. '-S-7>', function()
  local ok, comment_api = pcall(require, 'Comment.api')
  if ok then
    local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'nx', false)
    comment_api.toggle.linewise(vim.fn.visualmode())
  end
end, { silent = true, desc = 'Toggle comment' })

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
  local ok, telescope = pcall(require, 'telescope')
  local ok2, themes = pcall(require, 'telescope.themes')
  if ok and ok2 then
    telescope.extensions.frecency.frecency(themes.get_dropdown({
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
  end
end, { silent = true, desc = 'Find Files (Recent)' })

vim.keymap.set('n', '<C-S-p>', function()
  local ok, builtin = pcall(require, 'telescope.builtin')
  local ok2, themes = pcall(require, 'telescope.themes')
  if ok and ok2 then
    builtin.commands(themes.get_dropdown({
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
  end
end, { silent = true, desc = 'Command Palette' })

vim.keymap.set('n', '<C-S-f>', function()
  local ok, builtin = pcall(require, 'telescope.builtin')
  if ok then
    builtin.live_grep()
  end
end, { silent = true, desc = 'Search text in all files (live grep)' })

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

-- Telescope search keymaps (lazy-loaded to avoid requiring before plugin loads)
vim.keymap.set('n', '<leader>sh', function() require('telescope.builtin').help_tags() end, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', function() require('telescope.builtin').keymaps() end, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', function() require('telescope.builtin').find_files() end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', function() require('telescope.builtin').builtin() end, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', function() require('telescope.builtin').grep_string() end, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', function() require('telescope.builtin').live_grep() end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', function() require('telescope.builtin').diagnostics() end, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', function() require('telescope.builtin').resume() end, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', function() require('telescope.builtin').oldfiles() end, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', function() require('telescope.builtin').buffers() end, { desc = '[ ] Find existing buffers' })

-- LSP keybindings
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to declaration' })
vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Go to references' })
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation' })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })

-- Ctrl+Click for go-to-definition (cross-platform)
vim.keymap.set('n', '<C-LeftMouse>', '<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>', { desc = 'Go to definition (Ctrl+Click)' })

-- Project management - Cmd+Shift+O on macOS, Ctrl+Shift+O elsewhere
-- Sessions are automatically saved when you work in a directory
-- No need to manually "save" - just work and the project will appear in history
vim.keymap.set('n', '<' .. mod .. '-S-o>', '<cmd>NeovimProjectHistory<CR>', { silent = true, desc = 'Open Project' })
vim.keymap.set('n', '<leader>pp', '<cmd>NeovimProjectHistory<CR>', { desc = 'Projects' })
