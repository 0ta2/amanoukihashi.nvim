local tmux = require("amanoukihashi.tmux")

describe("tmux", function()
  local orig_system
  local orig_session_name
  local orig_v

  before_each(function()
    orig_system = vim.fn.system
    orig_session_name = tmux.session_name
    orig_v = vim.v
    tmux.session_name = function() return "test_session" end
  end)

  after_each(function()
    vim.fn.system = orig_system
    tmux.session_name = orig_session_name
    vim.v = orig_v
  end)

  it("capture はセッションの履歴テキストを返す", function()
    vim.v = setmetatable({shell_error = 0}, {__index = orig_v})
    vim.fn.system = function(args)
      assert.same({ "tmux", "capture-pane", "-p", "-S", "-", "-t", "test_session" }, args)
      return "line1\nline2\n"
    end
    local result = tmux.capture("default")
    assert.equal("line1\nline2\n", result)
  end)

  it("capture は tmux が空文字列を返したとき空文字列を返す", function()
    vim.v = setmetatable({shell_error = 0}, {__index = orig_v})
    vim.fn.system = function(args)
      assert.same({ "tmux", "capture-pane", "-p", "-S", "-", "-t", "test_session" }, args)
      return ""
    end
    local result = tmux.capture("default")
    assert.equal("", result)
  end)

  it("capture はシェルエラー時に nil を返す", function()
    vim.v = setmetatable({shell_error = 1}, {__index = orig_v})
    vim.fn.system = function(args)
      assert.same({ "tmux", "capture-pane", "-p", "-S", "-", "-t", "test_session" }, args)
      return ""
    end
    local result = tmux.capture("default")
    assert.is_nil(result)
  end)
end)
