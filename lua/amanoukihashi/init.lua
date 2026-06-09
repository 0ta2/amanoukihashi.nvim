local M = {}

function M.setup(opts)
  require("amanoukihashi.config").setup(opts)
  require("amanoukihashi.ctx").setup()
  require("amanoukihashi.watch").enable()
end

function M.toggle(name, opts)
  require("amanoukihashi.toggle").toggle(name, opts)
end

function M.list()
  local sessions = require("amanoukihashi.tmux").list_sessions()
  if #sessions == 0 then
    vim.notify("amanoukihashi: no sessions", vim.log.levels.WARN)
    return
  end
  vim.ui.select(sessions, {
    prompt = "amanoukihashi session:",
    format_item = function(s)
      return (s.active and "● " or "○ ") .. s.name
    end,
  }, function(s)
    if not s then return end
    require("amanoukihashi.toggle").focus(s.name)
  end)
end

local function send_impl(expr, name, send_fn)
  name = name or require("amanoukihashi.session").current()
  if not name then
    vim.notify("amanoukihashi: no active session", vim.log.levels.WARN)
    return
  end
  local text = require("amanoukihashi.context").expand(expr, require("amanoukihashi.ctx").get())
  send_fn(require("amanoukihashi.tmux"), name, text)
end

function M.send(expr, name)
  send_impl(expr, name, function(t, n, s) t.send_keys(n, s) end)
end

function M.insert(expr, name)
  send_impl(expr, name, function(t, n, s) t.send_text(n, s) end)
end

return M
