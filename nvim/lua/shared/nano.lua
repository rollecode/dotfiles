-- luacheck: globals vim
-- Nano-like modeless editing for Neovim.
--
-- Default: on. Typing just works, nano's Ctrl keys do nano things.
-- Esc:     drops to normal mode for a quick vim burst (nano mode stays on).
-- :Vim     turns nano mode off entirely and restores the normal setup.
-- :Nano    turns it back on. F12 toggles. Set vim.g.nano_default = false in
--          lua/local.lua to start in plain vim instead.
--
-- 'insertmode' was removed from Neovim (E519), so this follows the emulation
-- approach documented in :help vim_diff (BufWinEnter + startinsert), with
-- <Cmd> mappings so nothing has to leave insert mode.

local M = {}
local api = vim.api

M.enabled = false

local ns = api.nvim_create_namespace('nano')
local augroup = nil
local helper = { buf = nil, win = nil }
local saved = { maps = {}, opts = {} }
local last_search = ''
local cut = { buf = nil, line = nil, tick = nil }

-- Set while an action genuinely needs normal mode (the :s confirm prompt, quitting),
-- so the "always go back to typing" autocmd does not yank us out from under it.
local holding_normal = false

-- Shortcut rows drawn at the bottom, nano style.
-- Six columns per row, like nano, so nothing truncates at 80 columns.
-- Undo/redo (M-U / M-E) are bound too, they just live in ^G Help.
local ROWS = {
  {
    { '^G', 'Help' }, { '^O', 'Write Out' }, { '^W', 'Where Is' },
    { '^K', 'Cut' }, { '^T', 'Execute' }, { '^C', 'Location' },
  },
  {
    { '^X', 'Exit' }, { '^R', 'Read File' }, { '^\\', 'Replace' },
    { '^U', 'Paste' }, { '^_', 'Go To Line' }, { 'F12', 'Vim Mode' },
  },
}

--- Is this a buffer we should be typing in?
local function is_editable(buf)
  buf = buf or api.nvim_get_current_buf()
  return api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buftype == ''
    and vim.bo[buf].modifiable
    and buf ~= helper.buf
end

--- Return to insert mode after a command that had to leave it.
local function resume_insert()
  if not M.enabled then return end
  vim.schedule(function()
    if not M.enabled or not is_editable() then return end
    if api.nvim_get_mode().mode:sub(1, 1) == 'i' then return end
    local col = api.nvim_win_get_cursor(0)[2]
    local len = #api.nvim_get_current_line()
    if len > 0 and col >= len - 1 then
      vim.cmd('startinsert!')
    else
      vim.cmd('startinsert')
    end
  end)
end

--- blink.cmp owns some of nano's keys. Give them back only while its menu is
--- open, so completion keeps working and nano gets the key the rest of the time.
local function blink_or(action, fallback)
  return function()
    local ok, blink = pcall(require, 'blink.cmp')
    if ok and blink.is_menu_visible() and blink[action] then
      blink[action]()
      return
    end
    fallback()
  end
end

local function feed(keys)
  api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), 'n', false)
end

--- Literal (non-regex) search pattern, like nano searches.
local function literal(text)
  return '\\V' .. vim.fn.escape(text, '\\')
end

-- Editing actions ------------------------------------------------------------

--- ^K: cut the current line into the cutbuffer. Consecutive cuts append.
function M.cut_line()
  local buf = api.nvim_get_current_buf()
  local line = api.nvim_win_get_cursor(0)[1]
  local text = api.nvim_get_current_line()
  local tick = api.nvim_buf_get_changedtick(buf)

  local appending = cut.buf == buf and cut.line == line and cut.tick == tick
  if appending then
    local prev = vim.fn.getreg('n', 1, true)
    if type(prev) ~= 'table' then prev = { tostring(prev) } end
    table.insert(prev, text)
    vim.fn.setreg('n', prev, 'l')
  else
    vim.fn.setreg('n', { text }, 'l')
  end

  if api.nvim_buf_line_count(buf) == 1 then
    api.nvim_buf_set_lines(buf, 0, 1, false, { '' })
  else
    api.nvim_buf_set_lines(buf, line - 1, line, false, {})
  end

  local newline = math.min(line, api.nvim_buf_line_count(buf))
  api.nvim_win_set_cursor(0, { newline, 0 })
  cut.buf, cut.line, cut.tick = buf, newline, api.nvim_buf_get_changedtick(buf)
end

--- ^U: paste the cutbuffer above the cursor line.
function M.uncut()
  local lines = vim.fn.getreg('n', 1, true)
  if type(lines) ~= 'table' or #lines == 0 or (#lines == 1 and lines[1] == '') then
    vim.notify('Cutbuffer is empty', vim.log.levels.INFO)
    return
  end
  local buf = api.nvim_get_current_buf()
  local line = api.nvim_win_get_cursor(0)[1]
  api.nvim_buf_set_lines(buf, line - 1, line - 1, false, lines)
  local target = math.min(line + #lines, api.nvim_buf_line_count(buf))
  api.nvim_win_set_cursor(0, { target, 0 })
  cut.buf = nil
end

--- ^W: where is.
function M.search(backward)
  vim.ui.input({ prompt = backward and 'Search (backward): ' or 'Search: ', default = last_search },
    function(input)
      if input and input ~= '' then
        last_search = input
        local pat = literal(input)
        vim.fn.setreg('/', pat)
        vim.o.hlsearch = true
        if vim.fn.search(pat, backward and 'bw' or 'w') == 0 then
          vim.notify('"' .. input .. '" not found', vim.log.levels.WARN)
        end
      end
      resume_insert()
    end)
end

--- M-W: repeat the last search.
function M.search_next()
  if last_search == '' then
    return M.search()
  end
  if vim.fn.search(literal(last_search), 'w') == 0 then
    vim.notify('"' .. last_search .. '" not found', vim.log.levels.WARN)
  end
  resume_insert()
end

--- ^\: replace, asking for confirmation on each hit like nano.
function M.replace()
  vim.ui.input({ prompt = 'Search (to replace): ', default = last_search }, function(pat)
    if not pat or pat == '' then
      return resume_insert()
    end
    vim.ui.input({ prompt = 'Replace with: ' }, function(rep)
      if rep == nil then
        return resume_insert()
      end
      -- The gc confirm prompt drives itself from normal mode
      holding_normal = true
      vim.cmd('stopinsert')
      local from = '\\V' .. vim.fn.escape(pat, '\\/')
      local to = vim.fn.escape(rep, '\\/&~')
      local ok, err = pcall(vim.cmd, string.format('%%s/%s/%s/gc', from, to))
      if not ok then
        vim.notify(tostring(err), vim.log.levels.WARN)
      end
      holding_normal = false
      resume_insert()
    end)
  end)
end

--- ^O: write out, prompting with the current name prefilled.
function M.write_out()
  local name = api.nvim_buf_get_name(0)
  local default = name ~= '' and vim.fn.fnamemodify(name, ':~:.') or ''
  vim.ui.input({ prompt = 'File Name to Write: ', default = default, completion = 'file' }, function(input)
    if input and input ~= '' then
      local ok, err = pcall(vim.cmd, 'write ' .. vim.fn.fnameescape(vim.fn.expand(input)))
      if ok then
        vim.notify('Wrote ' .. input)
      else
        vim.notify(tostring(err), vim.log.levels.ERROR)
      end
    end
    resume_insert()
  end)
end

--- ^S: save straight away, no prompt.
function M.save()
  if api.nvim_buf_get_name(0) == '' then
    return M.write_out()
  end
  local ok, err = pcall(vim.cmd, 'write')
  if ok then
    vim.notify('Wrote ' .. vim.fn.expand('%:~:.'))
  else
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
  resume_insert()
end

--- ^X: exit, prompting about unsaved changes.
function M.exit()
  holding_normal = true
  vim.cmd('stopinsert')
  pcall(vim.cmd, 'confirm qall')
  holding_normal = false
  resume_insert()
end

--- ^T: run an ex command. Without this, `:` is unreachable when you never leave
--- insert mode, which would put :Vim, :Lazy and friends out of reach.
function M.execute()
  vim.ui.input({ prompt = ':', completion = 'command' }, function(cmd)
    if cmd and cmd ~= '' then
      local ok, err = pcall(vim.cmd, cmd)
      if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
      end
    end
    resume_insert()
  end)
end

--- ^R: read another file into this buffer.
function M.read_file()
  vim.ui.input({ prompt = 'File to insert: ', completion = 'file' }, function(input)
    if input and input ~= '' then
      local ok, err = pcall(vim.cmd, 'read ' .. vim.fn.fnameescape(vim.fn.expand(input)))
      if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
      end
    end
    resume_insert()
  end)
end

--- ^_: go to line.
function M.goto_line()
  vim.ui.input({ prompt = 'Enter line number: ' }, function(input)
    local n = tonumber(input)
    if n then
      n = math.max(1, math.min(n, api.nvim_buf_line_count(0)))
      api.nvim_win_set_cursor(0, { n, 0 })
    end
    resume_insert()
  end)
end

--- ^C: report where we are.
function M.position()
  local pos = api.nvim_win_get_cursor(0)
  local total = api.nvim_buf_line_count(0)
  vim.notify(string.format('line %d/%d (%d%%), col %d', pos[1], total,
    math.floor(pos[1] / total * 100), pos[2] + 1))
end

--- ^G: the help screen.
function M.help()
  local lines = {
    ' Nano mode ',
    '',
    '  ^G  Help                    ^A  Beginning of line',
    '  ^X  Exit                    ^E  End of line',
    '  ^O  Write out (save as)     ^Y  Page up',
    '  ^S  Save                    ^V  Page down',
    '  ^R  Read file in            ^P  Previous line',
    '  ^W  Where is (search)       ^N  Next line',
    '  M-W Repeat search           ^B  Back one char',
    '  ^\\  Replace                 ^F  Forward one char',
    '  ^K  Cut line (repeats add)  ^D  Delete char',
    '  ^U  Paste cutbuffer         ^_  Go to line',
    '  ^J  Justify paragraph       ^C  Where am I',
    '  ^T  Run a : command         ^L  Redraw',
    '  M-U Undo                    M-E Redo',
    '',
    '  Every key works in every mode. Shift+arrows select. Mouse works.',
    '  You are always typing: nvim will not strand you in normal mode.',
    '',
    '  ^T    reaches : commands (:Lazy, :Vim, ...) without leaving insert',
    '  F12   turn nano mode off completely (:Vim), press again for :Nano',
    '',
    '  Press q to close.',
  }
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end
  local win = api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width + 2,
    height = #lines,
    row = math.max(0, math.floor((vim.o.lines - #lines) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = 'minimal',
    border = 'rounded',
    title = ' GNU nano (well, Neovim) ',
    title_pos = 'center',
  })
  vim.wo[win].cursorline = false
  vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', '<Cmd>close<CR>', { buffer = buf, nowait = true })
end

-- Helper bar -----------------------------------------------------------------

local function set_highlights()
  api.nvim_set_hl(0, 'NanoKey', { reverse = true, default = true })
  api.nvim_set_hl(0, 'NanoBar', { link = 'Normal', default = true })
end

function M.render_helper()
  if not (helper.win and api.nvim_win_is_valid(helper.win)) then return end
  local width = api.nvim_win_get_width(helper.win)
  local ncols = #ROWS[1]
  local colw = math.max(12, math.floor(width / ncols))

  local lines, marks = {}, {}
  for r, row in ipairs(ROWS) do
    local parts, col = {}, 0
    for _, item in ipairs(row) do
      local key, label = item[1], item[2]
      local text = key .. ' ' .. label
      if #text > colw - 1 then
        text = text:sub(1, colw - 1)
      end
      table.insert(marks, { r - 1, col, col + #key })
      table.insert(parts, text .. string.rep(' ', math.max(0, colw - #text)))
      col = col + colw
    end
    lines[r] = table.concat(parts)
  end

  vim.bo[helper.buf].modifiable = true
  api.nvim_buf_set_lines(helper.buf, 0, -1, false, lines)
  vim.bo[helper.buf].modifiable = false

  api.nvim_buf_clear_namespace(helper.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    pcall(api.nvim_buf_set_extmark, helper.buf, ns, m[1], m[2],
      { end_col = m[3], hl_group = 'NanoKey' })
  end
end

local function open_helper()
  if helper.win and api.nvim_win_is_valid(helper.win) then return end
  local cur = api.nvim_get_current_win()

  helper.buf = api.nvim_create_buf(false, true)
  vim.bo[helper.buf].buftype = 'nofile'
  vim.bo[helper.buf].swapfile = false
  vim.bo[helper.buf].filetype = 'nanobar'
  vim.bo[helper.buf].modifiable = false

  vim.cmd('botright 2split')
  helper.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(helper.win, helper.buf)
  api.nvim_win_set_height(helper.win, 2)

  local wo = vim.wo[helper.win]
  wo.number = false
  wo.relativenumber = false
  wo.cursorline = false
  wo.signcolumn = 'no'
  wo.winfixheight = true
  wo.list = false
  wo.wrap = false
  wo.winhighlight = 'Normal:NanoBar,EndOfBuffer:NanoBar'

  api.nvim_set_current_win(cur)
  M.render_helper()
end

local function close_helper()
  if helper.win and api.nvim_win_is_valid(helper.win) then
    pcall(api.nvim_win_close, helper.win, true)
  end
  if helper.buf and api.nvim_buf_is_valid(helper.buf) then
    pcall(api.nvim_buf_delete, helper.buf, { force = true })
  end
  helper.win, helper.buf = nil, nil
end

-- Keymaps --------------------------------------------------------------------

local function keymaps()
  local page_up = function() feed('<PageUp>') end
  local page_down = function() feed('<PageDown>') end

  -- Every mode, because you should never have to know which one you are in.
  -- Normal mode is still where plugins and `normal!` commands do their work, so the
  -- keys have to answer there too, not just while typing.
  local A = { 'i', 'n', 'v', 's' }
  local MOVE = { 'i', 'n' }

  return {
    -- File
    { A, '<C-o>', M.write_out, 'Write out' },
    { A, '<C-s>', M.save, 'Save' },
    { A, '<C-x>', M.exit, 'Exit' },
    { A, '<C-r>', M.read_file, 'Read file' },
    { A, '<C-g>', M.help, 'Help' },
    { A, '<C-t>', M.execute, 'Execute command' },

    -- Search and replace
    { A, '<C-w>', function() M.search(false) end, 'Where is' },
    { A, '<C-q>', function() M.search(true) end, 'Where was' },
    { A, '<M-w>', M.search_next, 'Repeat search' },
    { A, '<C-_>', M.goto_line, 'Go to line' },
    { A, '<M-g>', M.goto_line, 'Go to line' },
    { A, '<C-\\>', M.replace, 'Replace' },

    -- Cut and paste
    { MOVE, '<C-k>', M.cut_line, 'Cut line' },
    { MOVE, '<C-u>', M.uncut, 'Paste cutbuffer' },
    { { 'v', 's' }, '<C-k>', '"nd', 'Cut selection' },
    { { 'v', 's' }, '<M-6>', '"ny', 'Copy selection' },

    -- Movement (nano's reading of the control keys)
    { MOVE, '<C-a>', function() feed('<Home>') end, 'Beginning of line' },
    { MOVE, '<C-e>', blink_or('cancel', function() feed('<End>') end), 'End of line' },
    { MOVE, '<C-p>', blink_or('select_prev', function() feed('<Up>') end), 'Previous line' },
    { MOVE, '<C-n>', blink_or('select_next', function() feed('<Down>') end), 'Next line' },
    { MOVE, '<C-b>', blink_or('scroll_documentation_up', function() feed('<Left>') end), 'Back one char' },
    { MOVE, '<C-f>', blink_or('scroll_documentation_down', function() feed('<Right>') end), 'Forward one char' },
    { MOVE, '<C-y>', blink_or('select_and_accept', page_up), 'Page up' },
    { MOVE, '<C-v>', page_down, 'Page down' },
    { MOVE, '<C-d>', function() feed('<Del>') end, 'Delete char' },

    -- Misc
    { MOVE, '<C-j>', function() vim.cmd('normal! gqap') end, 'Justify' },
    { A, '<C-c>', M.position, 'Where am I' },
    { A, '<C-l>', function() vim.cmd('mode') end, 'Redraw' },
    { A, '<M-u>', function() vim.cmd('undo') end, 'Undo' },
    { A, '<M-e>', function() vim.cmd('redo') end, 'Redo' },
  }
end

local cached = nil
local function all_maps()
  if not cached then cached = keymaps() end
  return cached
end

--- Whatever a nano key does, you end up typing again afterwards. Without this,
--- a key pressed from normal mode would leave you sitting in normal mode.
local function wrapped(rhs)
  if type(rhs) ~= 'function' then return rhs end
  return function()
    rhs()
    resume_insert()
  end
end

-- blink.cmp re-applies buffer-local keymaps on every InsertEnter, which would
-- shadow anything global we set. So we mirror its trick and re-apply ours to the
-- buffer right after it, which also keeps us ahead of autopairs and LspAttach maps.
local mapped_bufs = {}

local function apply_buffer_keymaps(buf)
  if not (buf and api.nvim_buf_is_valid(buf) and is_editable(buf)) then return end
  for _, map in ipairs(all_maps()) do
    local modes = type(map[1]) == 'table' and map[1] or { map[1] }
    for _, mode in ipairs(modes) do
      if mode == 'i' then
        vim.keymap.set('i', map[2], wrapped(map[3]),
          { silent = true, buffer = buf, desc = 'nano: ' .. map[4] })
      end
    end
  end
  mapped_bufs[buf] = true
end

-- blink.cmp only applies its keymaps to a buffer if none of its own are already
-- there (it looks for desc == 'blink.cmp'). Because we overwrite some of its keys
-- but not others, the leftovers make it think it is done and it never restores the
-- ones we took. Clearing all of them lets its own guard pass and re-apply cleanly
-- on the next InsertEnter.
local function reset_blink(buf)
  for _, mode in ipairs({ 'i', 's' }) do
    for _, mapping in ipairs(api.nvim_buf_get_keymap(buf, mode)) do
      if mapping.desc == 'blink.cmp' then
        pcall(api.nvim_buf_del_keymap, buf, mode, mapping.lhs)
      end
    end
  end
end

local function clear_buffer_keymaps()
  for buf in pairs(mapped_bufs) do
    if api.nvim_buf_is_valid(buf) then
      for _, map in ipairs(all_maps()) do
        local modes = type(map[1]) == 'table' and map[1] or { map[1] }
        for _, mode in ipairs(modes) do
          if mode == 'i' then
            pcall(vim.keymap.del, 'i', map[2], { buffer = buf })
          end
        end
      end
      reset_blink(buf)
    end
  end
  mapped_bufs = {}
end

local function apply_keymaps()
  saved.maps = {}
  for _, map in ipairs(all_maps()) do
    local modes, lhs, rhs, desc = map[1], map[2], map[3], map[4]
    modes = type(modes) == 'table' and modes or { modes }
    for _, mode in ipairs(modes) do
      local existing = vim.fn.maparg(lhs, mode, false, true)
      if existing and not vim.tbl_isempty(existing) then
        table.insert(saved.maps, existing)
      end
      vim.keymap.set(mode, lhs, wrapped(rhs), { silent = true, desc = 'nano: ' .. desc })
    end
  end
end

local function clear_keymaps()
  for _, map in ipairs(all_maps()) do
    local modes, lhs = map[1], map[2]
    modes = type(modes) == 'table' and modes or { modes }
    for _, mode in ipairs(modes) do
      pcall(vim.keymap.del, mode, lhs)
    end
  end
  for _, m in ipairs(saved.maps) do
    pcall(vim.fn.mapset, m)
  end
  saved.maps = {}
end

-- Enable / disable -----------------------------------------------------------

local OPTIONS = {
  relativenumber = false,        -- meaningless without counts
  laststatus = 0,                -- nano has no statusline, the cmdline is it
  showmode = false,
  keymodel = 'startsel,stopsel', -- shift+arrows select, like every other editor
  selectmode = 'key',
  whichwrap = 'b,s,<,>,[,]',     -- arrows wrap across lines
}

function M.enable()
  if M.enabled then return end
  M.enabled = true

  for opt, value in pairs(OPTIONS) do
    saved.opts[opt] = vim.o[opt]
    vim.o[opt] = value
  end
  vim.o.winbar = '%#NanoBar# nvim nano %=%f %{&modified ? "Modified" : ""}%='

  set_highlights()
  apply_keymaps()
  open_helper()

  augroup = api.nvim_create_augroup('nano', { clear = true })

  api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter', 'BufEnter' }, {
    group = augroup,
    callback = function(ev)
      if not M.enabled or not is_editable(ev.buf) then return end
      if api.nvim_get_current_win() == helper.win then return end
      if api.nvim_get_mode().mode:sub(1, 1) ~= 'i' then
        vim.cmd('startinsert')
      end
    end,
  })

  -- You should never be stranded in a mode where typing runs commands instead of
  -- inserting text. If we land in normal mode inside a real file buffer, go back to
  -- typing. Only file buffers, so Telescope, mini.files, help and Trouble keep their
  -- normal-mode navigation, and never while an action is deliberately holding it.
  api.nvim_create_autocmd('ModeChanged', {
    group = augroup,
    pattern = '*:n',
    callback = function()
      if not M.enabled or holding_normal or not is_editable() then return end
      vim.schedule(function()
        if not M.enabled or holding_normal or not is_editable() then return end
        if api.nvim_get_mode().mode ~= 'n' then return end
        vim.cmd('startinsert')
      end)
    end,
  })

  -- Registered after blink.cmp's own InsertEnter handler, so ours lands last.
  api.nvim_create_autocmd('InsertEnter', {
    group = augroup,
    callback = function(ev) apply_buffer_keymaps(ev.buf) end,
  })

  -- Never let the cursor land in the shortcut bar.
  api.nvim_create_autocmd('WinEnter', {
    group = augroup,
    callback = function()
      if helper.win and api.nvim_get_current_win() == helper.win then
        vim.cmd('wincmd p')
      end
    end,
  })

  api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = augroup,
    callback = function() M.render_helper() end,
  })

  api.nvim_create_autocmd('ColorScheme', {
    group = augroup,
    callback = function() set_highlights() end,
  })

  if is_editable() then
    apply_buffer_keymaps(api.nvim_get_current_buf())
    vim.cmd('startinsert')
  end
end

function M.disable()
  if not M.enabled then return end
  M.enabled = false

  if augroup then
    pcall(api.nvim_del_augroup_by_id, augroup)
    augroup = nil
  end

  clear_buffer_keymaps() -- blink.cmp re-applies its own on the next InsertEnter
  clear_keymaps()
  close_helper()

  for opt, value in pairs(saved.opts) do
    vim.o[opt] = value
  end
  saved.opts = {}
  vim.o.winbar = ''
  vim.cmd('stopinsert')
end

function M.toggle()
  if M.enabled then
    M.disable()
    vim.notify('Vim mode')
  else
    M.enable()
    vim.notify('Nano mode')
  end
end

--- On unless turned off. `enable_nano = false` in lua/local.lua is the switch that
--- plugins.lua reads too, so turning nano off there brings the dashboard back.
--- vim.g.nano_default wins over it, for flipping the default without a restart.
local function default_on()
  if vim.g.nano_default ~= nil then
    return vim.g.nano_default
  end
  local ok, cfg = pcall(require, 'local')
  if ok and type(cfg) == 'table' and cfg.enable_nano ~= nil then
    return cfg.enable_nano
  end
  return true
end

function M.setup()
  api.nvim_create_user_command('Nano', M.enable, { desc = 'Enable nano-like editing' })
  api.nvim_create_user_command('Vim', M.disable, { desc = 'Back to plain vim' })
  api.nvim_create_user_command('NanoToggle', M.toggle, { desc = 'Toggle nano mode' })
  vim.keymap.set({ 'n', 'i', 'v' }, '<F12>', M.toggle, { silent = true, desc = 'Toggle nano/vim mode' })

  if not default_on() then return end

  -- After plugins have registered their own keymaps, so ours win.
  api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function() vim.schedule(M.enable) end,
  })
end

return M
