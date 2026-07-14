-- Linux-specific configuration

-- Python provider configuration
vim.g.python3_host_prog = '/usr/bin/python3'

-- Compare version dir names like "v22.20.0", numerically, so v9 does not beat v22
local function newer(a, b)
  local function parts(dir)
    local v = vim.fn.fnamemodify(dir, ':t'):gsub('^v', '')
    local out = {}
    for n in v:gmatch('%d+') do
      table.insert(out, tonumber(n))
    end
    return out
  end
  local pa, pb = parts(a), parts(b)
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i] or 0, pb[i] or 0
    if x ~= y then return x < y end
  end
  return false
end

-- Add nvm's node to PATH so linters can find npm-installed tools.
-- Resolved without spawning a shell: `bash -c "source nvm.sh && nvm which current"`
-- cost about 70ms of the ~225ms startup, on every single launch, because
-- ~/.nvm/current does not exist on this machine and it always hit the fallback.
local function nvm_bin()
  local current = vim.fn.expand('~/.nvm/current/bin')
  if vim.fn.isdirectory(current) == 1 then
    return current
  end

  local alias = ''
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand('~/.nvm/alias/default'))
  if ok and lines and lines[1] then
    alias = vim.trim(lines[1])
  end

  local versions = vim.fn.expand('~/.nvm/versions/node')
  local dirs = {}
  if alias ~= '' then
    dirs = vim.fn.glob(versions .. '/v' .. alias .. '*', false, true)
  end
  if #dirs == 0 then
    dirs = vim.fn.glob(versions .. '/v*', false, true)
  end
  if #dirs == 0 then
    return nil
  end

  table.sort(dirs, newer)
  return dirs[#dirs] .. '/bin'
end

local bin = nvm_bin()
if bin then
  vim.env.PATH = bin .. ':' .. vim.env.PATH
end
