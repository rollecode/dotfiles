-- Linux-specific configuration

-- Python provider configuration
vim.g.python3_host_prog = '/usr/bin/python3'

-- Add nvm node to PATH so linters can find npm-installed tools
-- Dynamically find the current nvm node version
local nvm_node = vim.fn.expand('~/.nvm/current/bin')
if vim.fn.isdirectory(nvm_node) == 0 then
  -- Fallback: find the currently active node via nvm
  nvm_node = vim.fn.system('bash -c "source ~/.nvm/nvm.sh && nvm which current"'):gsub('/bin/node\n', '/bin')
end
vim.env.PATH = nvm_node .. ':' .. vim.env.PATH
