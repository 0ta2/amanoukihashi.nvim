local M = {}

local sessions     = {}
local current_name = nil

function M.get(name)
  local s = sessions[name]
  if s and vim.api.nvim_buf_is_valid(s.buf) then
    return s
  end
end

-- tmux セッションを作成または既存に再アタッチし、ウィンドウ内でターミナルを起動する
function M.open(name, cmd, win)
  if vim.fn.executable("tmux") ~= 1 then
    error("amanoukihashi: tmux が見つかりません。tmux をインストールしてください")
  end
  local s = sessions[name]
  if s and vim.api.nvim_buf_is_valid(s.buf) then
    M.resize(win)
    return s
  end
  if s then
    pcall(vim.fn.jobstop, s.job_id)
  end

  local tmux = require("amanoukihashi.tmux")
  local w = vim.api.nvim_win_get_width(win)
  local h = vim.api.nvim_win_get_height(win)
  local term_cmd = tmux.session_exists(name)
    and tmux.join_session_cmd(name)
    or  tmux.new_session_cmd(name, cmd, w, h)

  local job_id
  vim.api.nvim_win_call(win, function()
    job_id = vim.fn.jobstart(term_cmd, { term = true })
  end)
  if not job_id or job_id <= 0 then
    error(("amanoukihashi: jobstart failed for session: %s cmd: %s"):format(name, vim.inspect(term_cmd)))
  end
  -- { term = true } は jobstart 後にウィンドウのバッファを新しいターミナルバッファに置き換えるため後置
  local buf = vim.api.nvim_win_get_buf(win)
  -- TUI アプリは自前でスクリーンを管理するため Neovim のスクロールバックは不要。
  -- 大きな scrollback だとポップアップ描画時に行が押し出されカーソルがズレる
  vim.bo[buf].scrollback = 1
  sessions[name] = { buf = buf, job_id = job_id }
  -- 新規セッションは new_session_cmd で正しいサイズを渡済み。即時 resize は不要で、
  -- シェルの初回描画完了前に SIGWINCH が届くとカーソル位置がズレる原因になる
  return sessions[name]
end

-- tmux セッションを kill してテーブルから除去する
function M.kill(name)
  local s = sessions[name]
  if s then
    pcall(vim.fn.jobstop, s.job_id)
    pcall(vim.api.nvim_buf_delete, s.buf, { force = true })
    sessions[name] = nil
  end
  require("amanoukihashi.tmux").kill_session(name)
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
