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

-- Override gamify's check_streak to handle DST properly
function _G.CheckStreakDST()
  local ok, storage = pcall(require, 'gamify.storage')
  if not ok then return end

  local data = storage.load_data()
  if not data or type(data.date) ~= 'table' or #data.date == 0 then
    return
  end

  local dates = data.date
  local streak = 1

  -- Convert dates to timestamps
  local timestamps = {}
  for _, date in ipairs(dates) do
    local year, month, day = date:match '(%d+)-(%d+)-(%d+)'
    local time = os.time { year = year, month = month, day = day, hour = 12, min = 0, sec = 0 }
    table.insert(timestamps, time)
  end

  -- Sort newest first
  table.sort(timestamps, function(a, b) return a > b end)

  -- Calculate streak (allowing for DST: 23-25 hour days)
  for i = 2, #timestamps do
    local difference = os.difftime(timestamps[i - 1], timestamps[i])
    -- Check if difference is approximately 1 day (23-25 hours)
    if difference >= 82800 and difference <= 90000 then
      streak = streak + 1
    else
      break
    end
  end

  data.day_streak = streak
  storage.save_data(data)
end
