local M = {}

local NEW_LABEL = "+ new session"

local _win = nil
local _buf = nil
local _anchor = nil
local _sessions = {}
local _cfg = nil

local function clamp_height(n, max_h)
  return math.max(math.min(n, max_h), 1)
end

local function merge_attention(sessions)
  local status = require("amanoukihashi.tmux").attention_status()
  for _, s in ipairs(sessions) do
    s.needs_attention = status[s.name] == true
  end
  return sessions
end

function M.render_lines(sessions)
  local lines = {}
  for _, s in ipairs(sessions) do
    local mark = s.needs_attention and "⚠ " or ""
    lines[#lines + 1] = mark .. (s.active and "● " or "○ ") .. s.name
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

function M._on_enter()
  if not M.is_open() then return end
  local line = vim.api.nvim_win_get_cursor(_win)[1]
  local action, s = M.action_for(line, _sessions)
  if action == "refocus" then
    if _anchor and vim.api.nvim_win_is_valid(_anchor) then
      vim.api.nvim_set_current_win(_anchor)
    end
  elseif action == "switch" then
    require("amanoukihashi.toggle").focus(s.name)
    M.refresh()
  else
    vim.ui.input({ prompt = "session name: " }, function(input)
      if input and input ~= "" then
        -- 新規セッションは jobstart が非同期なため、ここで refresh しても
        -- tmux 上にまだセッションが存在せず無駄になる。window.lua の
        -- TermOpen ハンドラ経由の refresh に任せる
        require("amanoukihashi.toggle").focus(input)
      end
    end)
  end
end

function M.open(anchor_win, cfg)
  if M.is_open() then return end
  _anchor = anchor_win
  _cfg = cfg
  _sessions = merge_attention(require("amanoukihashi.tmux").list_sessions())
  _buf = vim.api.nvim_create_buf(false, true)
  vim.bo[_buf].buftype = "nofile"
  vim.bo[_buf].bufhidden = "wipe"
  local lines = apply_buf(_sessions)
  local h = clamp_height(#lines, cfg.list.max_height)
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
  -- このバッファは buftype=nofile で dropbar の enable 条件 (terminal/markdown/
  -- treesitter/lsp) を満たさないため winbar 上書き対策は不要。winbar を立てると
  -- パネル分の必要高さが画面に収まらず表示崩れの原因になるため設定しない
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
  _cfg = nil
end

function M._reset()
  pcall(M.close)
end

function M.refresh()
  if not M.is_open() then return end
  _sessions = merge_attention(require("amanoukihashi.tmux").list_sessions())
  local lines = apply_buf(_sessions)
  pcall(vim.api.nvim_win_set_height, _win, clamp_height(#lines, _cfg.list.max_height))
end

return M
