local M = {}

local function get_selection(ctx)
  local s = vim.api.nvim_buf_get_mark(ctx.buf, "<")
  local e = vim.api.nvim_buf_get_mark(ctx.buf, ">")
  if s[1] == 0 or e[1] == 0 then return "" end

  local s_row = s[1] - 1
  local s_col = s[2]
  local e_row = e[1] - 1
  local e_col = e[2] + 1  -- nvim_buf_get_mark col は 0-indexed 包含 → +1 で排他端

  -- vim.v.maxcol 対策: 行末でキャップ
  local line = vim.api.nvim_buf_get_lines(ctx.buf, e_row, e_row + 1, false)[1] or ""
  e_col = math.min(e_col, #line)

  local ok, lines = pcall(vim.api.nvim_buf_get_text, ctx.buf, s_row, s_col, e_row, e_col, {})
  if not ok then return "" end
  return table.concat(lines, "\n")
end

local function make_resolvers(ctx)
  return {
    file = function()
      local name = vim.api.nvim_buf_get_name(ctx.buf)
      if name == "" then return "" end
      return vim.fn.fnamemodify(name, ":.")
    end,
    selection = function()
      return get_selection(ctx)
    end,
  }
end

function M.expand(expr, ctx)
  local resolvers = make_resolvers(ctx)
  return (expr:gsub("{(%w+)}", function(var)
    local fn = resolvers[var]
    if fn then return fn() end
    return "{" .. var .. "}"
  end))
end

return M
