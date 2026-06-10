local M = {}

local function start_session(name, cmd, win, on_fail)
  local ok, ns = pcall(require("amanoukihashi.session").open, name, cmd, win)
  if not ok then
    vim.notify(ns, vim.log.levels.ERROR)
    on_fail()
    return false
  end
  vim.api.nvim_set_current_win(win)
  vim.cmd("startinsert")
  return true
end

-- window 未オープン時: 新規ウィンドウを開いて name のセッションを起動する
-- 常に新規アタッチ：tmux は新規クライアント接続時にウィンドウを正しいサイズで
-- 全画面送信するため、バッファ再利用による描画崩れ（旧幅でのカーソル計算ズレ）を防ぐ
-- 成功: true / 失敗: ウィンドウを閉じてバッファを破棄し false
local function open_in_new_window(name, cmd, cfg, s)
  local session = require("amanoukihashi.session")
  local window  = require("amanoukihashi.window")
  if s then session.detach(name) end
  local buf = vim.api.nvim_create_buf(false, true)
  window.open(buf, cfg)
  return start_session(name, cmd, window.win(), function()
    window.close()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end

-- window オープン時: 現在のバッファを新規バッファに差し替えて name のセッションを起動する
-- 既存セッションも含め常に新規アタッチ：tmux は新規クライアント接続時に全画面を
-- 送信するため、バッファ再利用による表示崩れを防ぐ
-- 成功: true / 失敗: 元のバッファに戻して新バッファを破棄し false
local function swap_in_existing_window(name, cmd, cfg, s)
  local session = require("amanoukihashi.session")
  local window  = require("amanoukihashi.window")
  if s then session.detach(name) end
  require("amanoukihashi.scrollback").close(window.win())
  local prev_buf = vim.api.nvim_win_get_buf(window.win())
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(window.win(), buf)
  return start_session(name, cmd, window.win(), function()
    vim.api.nvim_win_set_buf(window.win(), prev_buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end

function M.toggle(name, opts)
  name = name:gsub("[^%w%-]", "_")
  opts = opts or {}
  local cfg     = require("amanoukihashi.config").get()
  local session = require("amanoukihashi.session")
  local window  = require("amanoukihashi.window")
  local cmd = opts.cmd or cfg.default_cmd
  local s = session.get(name)

  if not window.is_open() then
    if open_in_new_window(name, cmd, cfg, s) then
      session.set_current(name)
    end
    return
  end

  if session.current() == name then
    session.set_current(nil)
    window.close()
    return
  end

  if swap_in_existing_window(name, cmd, cfg, s) then
    session.set_current(name)
  end
end

function M.focus(name, opts)
  name = name:gsub("[^%w%-]", "_")
  opts = opts or {}
  local cfg     = require("amanoukihashi.config").get()
  local session = require("amanoukihashi.session")
  local window  = require("amanoukihashi.window")
  local cmd     = opts.cmd or cfg.default_cmd
  local s       = session.get(name)

  local ok
  if window.is_open() then
    ok = swap_in_existing_window(name, cmd, cfg, s)
  else
    ok = open_in_new_window(name, cmd, cfg, s)
  end

  if ok then
    session.set_current(name)
  end
end

return M
