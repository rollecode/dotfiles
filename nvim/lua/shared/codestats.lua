-- Code::Stats configuration and setup

local secrets = require('secrets')

-- Set global API key and username
vim.g.codestats_api_key = secrets.codestats_api_key
vim.g.codestats_username = secrets.codestats_username

-- Simple code-stats implementation (no external dependencies needed)
local codestats = {
  xps = {}
}

function codestats.add_xp(language, xp)
  codestats.xps[language] = (codestats.xps[language] or 0) + xp
end

-- Make it globally available
_G.codestats = codestats

-- Set up code-stats autocommands for XP tracking
local codestats_group = vim.api.nvim_create_augroup("codestats", { clear = true })

-- Track each character typed in insert mode
vim.api.nvim_create_autocmd("InsertCharPre", {
  group = codestats_group,
  callback = function()
    vim.b.xp = (vim.b.xp or 0) + 1
  end,
})

-- When saving or leaving buffer, add XP to global counter
vim.api.nvim_create_autocmd({ "BufWrite", "BufLeave" }, {
  group = codestats_group,
  callback = function()
    if vim.b.xp and vim.b.xp > 0 then
      codestats.add_xp(vim.o.filetype, vim.b.xp)
      vim.b.xp = 0
    end
  end,
})

-- Send all XP to server when exiting Neovim
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = codestats_group,
  callback = function()
    -- First, make sure any remaining buffer XP is transferred
    if vim.b.xp and vim.b.xp > 0 then
      codestats.add_xp(vim.o.filetype, vim.b.xp)
      vim.b.xp = 0
    end

    -- Check if there's actually XP to send
    local has_xp = false
    for _ in pairs(codestats.xps) do
      has_xp = true
      break
    end

    if has_xp then
      -- Convert dictionary to array format required by API
      local xps_array = {}
      for language, xp in pairs(codestats.xps) do
        table.insert(xps_array, {
          language = language,
          xp = xp
        })
      end

      -- Clear the XP table
      codestats.xps = {}

      -- Prepare JSON data
      local json_data = vim.fn.json_encode({
        xps = xps_array,
        coded_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
      })

      -- Send using curl synchronously
      vim.fn.system({
        'curl', '-X', 'POST',
        '-H', 'Content-Type: application/json',
        '-H', 'User-Agent: code-stats-nvim/0.0.1',
        '-H', 'X-API-Token: ' .. vim.g.codestats_api_key,
        '-H', 'Accept: */*',
        '-d', json_data,
        'https://codestats.net/api/my/pulses'
      })
    end
  end,
})

-- Fetch today's XP when Neovim starts (after 1 second delay)
vim.defer_fn(function()
  _G.FetchTodayXP()
end, 1000)
