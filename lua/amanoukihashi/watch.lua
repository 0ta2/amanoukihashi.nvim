local M = {}

M._watches = {}

local _timer = nil

local function refresh()
  if _timer then
    _timer:stop()
    _timer:start(100, 0, vim.schedule_wrap(function()
      vim.cmd.checktime()
    end))
  end
end

local function buf_dir(buf)
  local fname = vim.api.nvim_buf_get_name(buf)
  if
    vim.api.nvim_buf_is_loaded(buf)
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].buflisted
    and fname ~= ""
    and vim.uv.fs_stat(fname) ~= nil
  then
    local path = vim.fs.dirname(fname)
    return (path and path ~= "") and path or nil
  end
end

local function start(path)
  if M._watches[path] then return end
  local watch = assert(vim.uv.new_fs_event())
  local ok, err = watch:start(path, {}, function(_, file)
    if file then refresh() end
  end)
  if not ok then
    if not watch:is_closing() then watch:close() end
    vim.notify("amanoukihashi: watch failed: " .. path .. ": " .. tostring(err), vim.log.levels.WARN)
    return
  end
  M._watches[path] = watch
end

local function stop(path)
  local w = M._watches[path]
  if w then
    M._watches[path] = nil
    if not w:is_closing() then w:close() end
  end
end

local function update()
  local dirs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local dir = buf_dir(buf)
    if dir then
      dirs[dir] = true
      start(dir)
    end
  end
  for path in pairs(M._watches) do
    if not dirs[path] then stop(path) end
  end
end

function M.enable()
  _timer = assert(vim.uv.new_timer())
  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("amanoukihashi_watch", { clear = true }),
    callback = update,
  })
  update()
end

function M.disable()
  pcall(vim.api.nvim_clear_autocmds, { group = "amanoukihashi_watch" })
  pcall(vim.api.nvim_del_augroup_by_name, "amanoukihashi_watch")
  for path in pairs(M._watches) do stop(path) end
  if _timer then
    _timer:stop()
    _timer:close()
    _timer = nil
  end
end

return M
