local M = {}

local _state = {}
-- win_id -> { buf: integer, original_buf: integer, augroup: integer }

function M.is_open(win)
  return _state[win] ~= nil
end

function M.open(win, session_name)
  if M.is_open(win) then
    M.close(win)
  end
  if not vim.api.nvim_win_is_valid(win) then return end

  local text = require("amanoukihashi.tmux").capture(session_name)
  if not text then
    vim.notify("amanoukihashi: tmux capture failed", vim.log.levels.WARN)
    return
  end

  local original_buf = vim.api.nvim_win_get_buf(win)
  local buf          = vim.api.nvim_create_buf(false, true)

  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].filetype   = "scrollback"

  local augroup = vim.api.nvim_create_augroup("amanoukihashi_scrollback_" .. win, { clear = true })

  vim.api.nvim_create_autocmd("WinClosed", {
    group    = augroup,
    pattern  = tostring(win),
    once     = true,
    callback = function()
      local ag = (_state[win] or {}).augroup
      _state[win] = nil
      if ag then pcall(vim.api.nvim_del_augroup_by_id, ag) end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end,
  })

  _state[win] = { buf = buf, original_buf = original_buf, augroup = augroup }

  local function close_insert()
    if M.is_open(win) then
      M.close(win)
      vim.cmd("startinsert")
    end
  end

  vim.keymap.set("n", "i", close_insert, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "a", close_insert, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "q", function() M.close(win) end, { buffer = buf, silent = true, nowait = true })

  vim.api.nvim_win_set_buf(win, buf)
  if #lines > 0 then
    vim.api.nvim_win_set_cursor(win, { #lines, 0 })
  end
end

function M.close(win)
  local s = _state[win]
  if not s then return end
  pcall(vim.api.nvim_del_augroup_by_id, s.augroup)
  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(s.original_buf) then
    vim.api.nvim_win_set_buf(win, s.original_buf)
  end
  pcall(vim.api.nvim_buf_delete, s.buf, { force = true })
  _state[win] = nil
end

function M.toggle(win, session_name)
  if M.is_open(win) then
    M.close(win)
  else
    M.open(win, session_name)
  end
end

function M._reset()
  _state = {}
end

return M
