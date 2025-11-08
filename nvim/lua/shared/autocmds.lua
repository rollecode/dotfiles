-- Autocommands (shared across all platforms)

-- Custom highlight colors - override variable colors (orange -> bright purple)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Change variables from orange to bright purple/other colors
    vim.api.nvim_set_hl(0, '@variable', { fg = '#c678dd' }) -- bright purple
    vim.api.nvim_set_hl(0, '@variable.builtin', { fg = '#bb9af7' }) -- purple
    vim.api.nvim_set_hl(0, '@variable.parameter', { fg = '#e0af68' }) -- yellow
    vim.api.nvim_set_hl(0, '@variable.member', { fg = '#73daca' }) -- teal
    -- Bash/shell specific
    vim.api.nvim_set_hl(0, '@variable.bash', { fg = '#c678dd' }) -- bright purple
    vim.api.nvim_set_hl(0, '@constant.bash', { fg = '#c678dd' }) -- bright purple for CONSTANTS

    -- Make breadcrumbs and bold text normal weight
    -- Dropbar breadcrumbs
    vim.api.nvim_set_hl(0, 'DropBarIconKindFile', { bold = false })
    vim.api.nvim_set_hl(0, 'DropBarIconKindFolder', { bold = false })
    vim.api.nvim_set_hl(0, 'DropBarIconKindMethod', { bold = false })
    vim.api.nvim_set_hl(0, 'DropBarIconKindFunction', { bold = false })

    -- General bold text (make it less bold by removing bold attribute)
    vim.api.nvim_set_hl(0, 'Bold', { bold = false })
  end,
})

-- Refresh lualine when XP changes
vim.api.nvim_create_autocmd({ "InsertCharPre", "BufWrite", "BufLeave" }, {
  callback = function()
    vim.defer_fn(function()
      pcall(function()
        require('lualine').refresh()
      end)
    end, 100)
  end,
})

-- Auto-restore session when opening nvim without arguments (only if persistence is enabled)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
  callback = function()
    if vim.fn.argc(-1) == 0 then
      -- Check if persistence is enabled
      local local_config = {}
      pcall(function() local_config = require('local') end)

      local is_enabled = true
      if local_config.enable_persistence ~= nil then
        is_enabled = local_config.enable_persistence
      end

      if is_enabled then
        local ok, persistence = pcall(require, "persistence")
        if ok then
          persistence.load()
        end
      end
    end
  end,
  nested = true,
})

-- Recalculate gamify streak on startup (fixes Syncthing sync and DST issues)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      pcall(function()
        _G.CheckStreakDST()
        require('lualine').refresh()
      end)
    end, 500)
  end,
})

-- Close Trouble when quitting the last buffer
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    local ok, trouble = pcall(require, "trouble")
    if ok then
      trouble.close()
    end
  end,
})

-- Highlight yanked text briefly and show message
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })

    local event = vim.v.event
    local lines = event.regcontents or {}
    local regtype = event.regtype or ''

    vim.schedule(function()
      local msg
      if regtype == 'v' then
        -- Characterwise yank
        local text = table.concat(lines, '\n')
        local chars = vim.fn.strchars(text)
        msg = chars .. " chars yanked"
      elseif #lines == 1 then
        msg = "1 line yanked"
      else
        msg = #lines .. " lines yanked"
      end
      print(msg)
    end)
  end,
})
