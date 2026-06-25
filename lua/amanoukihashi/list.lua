local M = {}

local NEW_LABEL = "+ new session"

local _win = nil
local _buf = nil
local _anchor = nil
local _sessions = {}

function M.render_lines(sessions)
  local lines = {}
  for _, s in ipairs(sessions) do
    lines[#lines + 1] = (s.active and "● " or "○ ") .. s.name
  end
  lines[#lines + 1] = NEW_LABEL
  return lines
end

function M.action_for(line, sessions)
  local n = #sessions
  if line >= 1 and line <= n then
    local s = sessions[line]
    if s.active then return "refocus" end
    return "switch", s
  end
  return "new"
end

function M.is_open()
  return _win ~= nil and vim.api.nvim_win_is_valid(_win)
end

-- テスト用: 一覧ウィンドウ id を返す
function M._win_for_test()
  return _win
end

local function apply_buf(sessions)
  local lines = M.render_lines(sessions)
  vim.bo[_buf].modifiable = true
  vim.api.nvim_buf_set_lines(_buf, 0, -1, false, lines)
  vim.bo[_buf].modifiable = false
  return lines
end

function M._on_enter() end

function M.open(anchor_win, cfg)
  if M.is_open() then return end
  _anchor = anchor_win
  _sessions = require("amanoukihashi.tmux").list_sessions()
  _buf = vim.api.nvim_create_buf(false, true)
  vim.bo[_buf].buftype = "nofile"
  vim.bo[_buf].bufhidden = "wipe"
  local lines = apply_buf(_sessions)
  local h = math.max(math.min(#lines, cfg.list.max_height), 1)
  _win = vim.api.nvim_open_win(_buf, false, {
    win = anchor_win,
    split = "above",
    height = h,
    style = "minimal",
  })
  vim.wo[_win].winfixheight   = true
  vim.wo[_win].winfixwidth    = true
  vim.wo[_win].number         = false
  vim.wo[_win].relativenumber = false
  vim.wo[_win].cursorline     = true
  vim.keymap.set("n", "<CR>", M._on_enter,
    { buffer = _buf, silent = true, desc = "amanoukihashi: select session" })
end

function M.close()
  if M.is_open() then
    pcall(vim.api.nvim_win_close, _win, true)
  end
  _win = nil
  _buf = nil
  _anchor = nil
  _sessions = {}
end

function M._reset()
  pcall(M.close)
end

function M.refresh()
  if not M.is_open() then return end
  _sessions = require("amanoukihashi.tmux").list_sessions()
  local lines = apply_buf(_sessions)
  local max_h = require("amanoukihashi.config").get().list.max_height
  pcall(vim.api.nvim_win_set_height, _win, math.max(math.min(#lines, max_h), 1))
end

return M
