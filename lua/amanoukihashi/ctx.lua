local M = {}

local _win = nil

local function is_terminal(win)
  if not vim.api.nvim_win_is_valid(win) then return false end
  return vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal"
end

function M.setup()
  vim.api.nvim_create_augroup("amanoukihashi_ctx", { clear = true })
  vim.api.nvim_create_autocmd("WinLeave", {
    group = "amanoukihashi_ctx",
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if not is_terminal(win) then
        _win = win
      end
    end,
  })
end

function M.get()
  local cur = vim.api.nvim_get_current_win()
  local win = (not is_terminal(cur)) and cur
              or ((_win and vim.api.nvim_win_is_valid(_win)) and _win or cur)
  local buf    = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  return {
    win = win,
    buf = buf,
    cwd = vim.fn.getcwd(win),
    row = cursor[1],
    col = cursor[2] + 1,
  }
end

function M._reset()
  _win = nil
end

return M
