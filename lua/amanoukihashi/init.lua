local M = {}

local function prompt_new_session(opts)
  vim.ui.input({ prompt = "session name: " }, function(input)
    if input and input ~= "" then
      require("amanoukihashi.toggle").toggle(input, opts)
    end
  end)
end

function M.setup(opts)
  require("amanoukihashi.config").setup(opts)
  require("amanoukihashi.ctx").setup()
  require("amanoukihashi.watch").enable()
end

function M.toggle(name, opts)
  if not name then
    local window  = require("amanoukihashi.window")
    local session = require("amanoukihashi.session")
    if window.is_open() then
      local current = session.current()
      if current then
        require("amanoukihashi.toggle").toggle(current, opts)
        return
      end
    end
    local sessions = require("amanoukihashi.tmux").list_sessions()
    if #sessions > 0 then
      M.list(sessions, opts)
    else
      prompt_new_session(opts)
    end
    return
  end
  require("amanoukihashi.toggle").toggle(name, opts)
end

function M.list(sessions, opts)
  sessions = sessions or require("amanoukihashi.tmux").list_sessions()
  if #sessions == 0 then
    vim.notify("amanoukihashi: no sessions", vim.log.levels.WARN)
    return
  end
  local NEW = {}  -- sentinel for "new session" entry
  local items = vim.list_extend(vim.deepcopy(sessions), { NEW })
  vim.ui.select(items, {
    prompt = "amanoukihashi session:",
    format_item = function(s)
      if s == NEW then return "+ new session" end
      return (s.active and "● " or "○ ") .. s.name
    end,
  }, function(s)
    if not s then return end
    if s == NEW then
      prompt_new_session(opts)
      return
    end
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
