-- Custom global functions (shared across all platforms)

-- Global variables to store today's XP from Code::Stats
_G.codestats_today_xp = 0
_G.codestats_loading = true

-- Function to fetch today's XP from Code::Stats API
function _G.FetchTodayXP()
  local secrets = require('secrets')
  local username = secrets.codestats_username

  if not username or username == '' then
    _G.codestats_loading = false
    return
  end

  -- Fetch user profile from public API
  vim.fn.jobstart({
    'curl', '-s',
    'https://codestats.net/api/users/' .. username
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        local json_str = table.concat(data, '')
        local ok, result = pcall(vim.fn.json_decode, json_str)
        if ok and result and result.dates then
          local today = os.date('%Y-%m-%d')
          if result.dates[today] then
            _G.codestats_today_xp = result.dates[today] or 0
          end
        end
      end
      _G.codestats_loading = false
      pcall(function() require('lualine').refresh() end)
    end,
    on_stderr = function()
      _G.codestats_loading = false
      pcall(function() require('lualine').refresh() end)
    end,
  })
end

-- Function to get code-stats XP for statusline
function _G.CodeStatsXP()
  if _G.codestats_loading then
    return 'XP: loading...'
  end

  local session_xp = 0
  local buffer_xp = vim.b.xp or 0
  session_xp = session_xp + buffer_xp

  local ok, codestats = pcall(require, 'code-stats')
  if ok and codestats.xps then
    for _, xp in pairs(codestats.xps) do
      session_xp = session_xp + xp
    end
  end

  local total_xp = _G.codestats_today_xp + session_xp
  return string.format('XP: %d', total_xp)
end

-- Function to get gamify streak for statusline
function _G.GamifyStreak()
  local ok, storage = pcall(require, 'gamify.storage')
  if ok then
    local data = storage.load_data()
    if data.day_streak and data.day_streak > 0 then
      return ' 🔥' .. data.day_streak .. ' day streak'
    end
  end
  return ''
end
