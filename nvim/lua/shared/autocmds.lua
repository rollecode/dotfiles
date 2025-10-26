-- Autocommands (shared across all platforms)

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

-- Auto-restore session when opening nvim without arguments
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
  callback = function()
    if vim.fn.argc(-1) == 0 then
      require("persistence").load()
    end
  end,
  nested = true,
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
