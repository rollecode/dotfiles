-- macOS-specific configuration

-- Python provider configuration (Homebrew)
vim.g.python3_host_prog = '/opt/homebrew/bin/python3'

-- Explicitly disable paste mode (macOS)
vim.o.paste = false

-- macOS-specific PATH adjustments
vim.env.PATH = '/opt/homebrew/bin:' .. vim.env.PATH
