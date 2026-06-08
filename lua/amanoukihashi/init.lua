local M = {}

function M.setup(opts)
  require("amanoukihashi.config").setup(opts)
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

return M
