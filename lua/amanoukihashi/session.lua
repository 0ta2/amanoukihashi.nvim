local M = {}

local sessions     = {}
local current_name = nil

function M.get(name)
  local s = sessions[name]
  if s and vim.api.nvim_buf_is_valid(s.buf) then
    return s
  end
end

-- ウィンドウコンテキストでターミナルを起動する（PTY が正しいサイズで初期化される）
function M.create_in_win(name, cmd, win)
  local s = sessions[name]
  if s and vim.api.nvim_buf_is_valid(s.buf) then
    return s
  end
  if s then
    pcall(vim.fn.jobstop, s.job_id)
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local job_id
  vim.api.nvim_win_call(win, function()
    job_id = vim.fn.termopen(cmd)
  end)
  if not job_id or job_id <= 0 then
    error(("amanoukihashi: termopen failed for cmd: %s"):format(vim.inspect(cmd)))
  end
  sessions[name] = { buf = buf, job_id = job_id }
  return sessions[name]
end

function M.resize(win)
  local buf = vim.api.nvim_win_get_buf(win)
  for _, s in pairs(sessions) do
    if s.buf == buf and s.job_id then
      pcall(vim.fn.jobresize, s.job_id,
        vim.api.nvim_win_get_width(win),
        vim.api.nvim_win_get_height(win))
      return
    end
  end
end

function M.current()
  return current_name
end

function M.set_current(name)
  current_name = name
end

function M._reset()
  for _, s in pairs(sessions) do
    pcall(vim.fn.jobstop, s.job_id)
  end
  sessions     = {}
  current_name = nil
end

return M
