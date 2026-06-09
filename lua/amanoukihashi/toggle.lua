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

function M.toggle(name, opts)
  name = name:gsub("[^%w%-]", "_")
  opts = opts or {}
  local cfg     = require("amanoukihashi.config").get()
  local session = require("amanoukihashi.session")
  local window  = require("amanoukihashi.window")
  local cmd = opts.cmd or cfg.default_cmd

  local s = session.get(name)

  if not window.is_open() then
    -- 常に新規アタッチ：tmux は新規クライアント接続時にウィンドウを正しいサイズで
    -- 全画面送信するため、バッファ再利用による描画崩れ（旧幅でのカーソル計算ズレ）を防ぐ
    if s then session.detach(name) end
    local buf = vim.api.nvim_create_buf(false, true)
    window.open(buf, cfg)
    if not start_session(name, cmd, window.win(), function()
      window.close()
      vim.api.nvim_buf_delete(buf, { force = true })
    end) then return end
    session.set_current(name)
    return
  end

  if session.current() == name then
    session.set_current(nil)
    window.close()
    return
  end

  -- 既存セッションも含め常に新規アタッチ：tmux は新規クライアント接続時に全画面を
  -- 送信するため、バッファ再利用による表示崩れを防ぐ
  if s then session.detach(name) end
  require("amanoukihashi.scrollback").close(window.win())
  local prev_buf = vim.api.nvim_win_get_buf(window.win())
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(window.win(), buf)
  if not start_session(name, cmd, window.win(), function()
    vim.api.nvim_win_set_buf(window.win(), prev_buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  end) then return end
  session.set_current(name)
end

function M.focus(name, opts)
  name = name:gsub("[^%w%-]", "_")
  opts = opts or {}
  local cfg     = require("amanoukihashi.config").get()
  local session = require("amanoukihashi.session")
  local window  = require("amanoukihashi.window")
  local cmd     = opts.cmd or cfg.default_cmd
  local s       = session.get(name)

  if not window.is_open() then
    -- 常に新規アタッチ（toggle と同様の理由）
    if s then session.detach(name) end
    local buf = vim.api.nvim_create_buf(false, true)
    window.open(buf, cfg)
    if not start_session(name, cmd, window.win(), function()
      window.close()
      vim.api.nvim_buf_delete(buf, { force = true })
    end) then return end
  else
    -- ウィンドウが開いている場合も常に新規アタッチ（閉じない）
    if s then session.detach(name) end
    require("amanoukihashi.scrollback").close(window.win())
    local prev_buf = vim.api.nvim_win_get_buf(window.win())
    local buf      = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(window.win(), buf)
    if not start_session(name, cmd, window.win(), function()
      vim.api.nvim_win_set_buf(window.win(), prev_buf)
      vim.api.nvim_buf_delete(buf, { force = true })
    end) then return end
  end
  session.set_current(name)
end

return M
