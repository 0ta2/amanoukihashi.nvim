local M = {}

function M.open_win()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = 40, height = 10, row = 0, col = 0,
  })
  return buf, win
end

return M
