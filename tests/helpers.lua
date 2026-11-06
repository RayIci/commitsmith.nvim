---Per-test fixtures: a temp working directory and temp XDG data/state homes,
---so settings never touch the real stdpath("data"). Every commitsmith module
---is unloaded after each test (settings computes its path at load time).
local H = {}

---@type string? working directory of the running test
H.dir = nil
---@type string? XDG_DATA_HOME of the running test
H.data = nil

local saved = {} ---@type table<string, string|false>

local function unload()
  for name in pairs(package.loaded) do
    if name == "commitsmith" or name:find("^commitsmith%.") then
      package.loaded[name] = nil
    end
  end
  pcall(vim.api.nvim_del_user_command, "Commitsmith")
end

function H.begin_test()
  local base = vim.fn.tempname()
  H.dir = base .. "-dir"
  H.data = base .. "-data"
  vim.fn.mkdir(H.dir, "p")
  vim.fn.mkdir(H.data, "p")
  for _, key in ipairs({ "XDG_DATA_HOME", "XDG_STATE_HOME", "PATH" }) do
    saved[key] = vim.env[key] or false
  end
  vim.env.XDG_DATA_HOME = H.data
  vim.env.XDG_STATE_HOME = base .. "-state"
  vim.cmd.cd(H.dir)
  unload()
end

function H.end_test()
  unload()
  vim.cmd("silent! %bwipeout!")
  for key, value in pairs(saved) do
    vim.env[key] = value or nil
  end
  vim.cmd.cd(vim.fn.stdpath("cache"))
  vim.fn.delete(H.dir, "rf")
  vim.fn.delete(H.data, "rf")
  H.dir, H.data = nil, nil
end

---Capture vim.notify messages for the duration of `fn`.
---@param fn fun()
---@return { msg: string, level: integer? }[]
function H.notifications(fn)
  local seen = {}
  local notify = vim.notify
  vim.notify = function(msg, level) ---@diagnostic disable-line: duplicate-set-field
    seen[#seen + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = notify
  if not ok then
    error(err, 0)
  end
  return seen
end

---A scratch buffer with the given filetype, made current.
---@param filetype string
---@return integer buf
function H.buffer(filetype)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = filetype
  return buf
end

return H
