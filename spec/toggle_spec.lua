local toggle  = require("amanoukihashi.toggle")
local window  = require("amanoukihashi.window")
local session = require("amanoukihashi.session")

local cfg = {
  layout      = "float",
  float       = { width = 0.45, height = 0.85, border = "rounded" },
  split       = { width = 0.40 },
  default_cmd = { "sh" },
}

describe("toggle", function()
  before_each(function()
    window._reset()
    session._reset()
    require("amanoukihashi.scrollback")._reset()
    package.loaded["amanoukihashi.config"] = { get = function() return cfg end }
    package.loaded["amanoukihashi.tmux"] = {
      session_exists   = function() return false end,
      new_session_cmd  = function() return { "sh" } end,
      join_session_cmd = function() return "sh" end,
      session_name     = function(n) return n end,
      kill_session     = function() end,
    }
  end)

  after_each(function()
    package.loaded["amanoukihashi.config"] = nil
    package.loaded["amanoukihashi.tmux"]   = nil
    if window.is_open() then pcall(window.close) end
  end)

  it("アクティブセッションをトグルで閉じると session.current が nil になる", function()
    session.set_current("test")
    local closed = false
    package.loaded["amanoukihashi.window"] = {
      is_open = function() return true end,
      close   = function() closed = true end,
      win     = function() return nil end,
    }

    toggle.toggle("test")

    assert.is_nil(session.current())
    assert.is_true(closed)
    package.loaded["amanoukihashi.window"] = nil
  end)
end)
