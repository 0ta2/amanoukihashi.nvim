local scrollback = require("amanoukihashi.scrollback")

local function tmux_stub(text)
  return {
    session_name     = function(n) return n end,
    session_exists   = function() return false end,
    new_session_cmd  = function() return "sh" end,
    join_session_cmd = function() return "sh" end,
    kill_session     = function() end,
    capture          = function() return text end,
  }
end

local function open_win()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = 40, height = 10, row = 0, col = 0,
  })
  return buf, win
end

describe("scrollback", function()
  before_each(function()
    scrollback._reset()
    package.loaded["amanoukihashi.tmux"] = tmux_stub("line1\nline2\nline3\n")
  end)

  after_each(function()
    package.loaded["amanoukihashi.tmux"] = nil
  end)

  it("is_open は初期状態で false を返す", function()
    local _, win = open_win()
    assert.is_false(scrollback.is_open(win))
    pcall(vim.api.nvim_win_close, win, true)
  end)

  it("open でウィンドウのバッファが差し替わる", function()
    local orig_buf, win = open_win()
    scrollback.open(win, "default")
    assert.are_not_equal(orig_buf, vim.api.nvim_win_get_buf(win))
    assert.is_true(scrollback.is_open(win))
    pcall(vim.api.nvim_win_close, win, true)
  end)

  it("open でバッファに履歴テキストが書き込まれる", function()
    local _, win = open_win()
    scrollback.open(win, "default")
    local buf = vim.api.nvim_win_get_buf(win)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.equal("line1", lines[1])
    assert.equal("line2", lines[2])
    assert.equal("line3", lines[3])
    pcall(vim.api.nvim_win_close, win, true)
  end)

  it("close で元バッファが復元される", function()
    local orig_buf, win = open_win()
    scrollback.open(win, "default")
    scrollback.close(win)
    assert.equal(orig_buf, vim.api.nvim_win_get_buf(win))
    assert.is_false(scrollback.is_open(win))
    vim.api.nvim_win_close(win, true)
  end)

  it("toggle が open と close を交互に切り替える", function()
    local _, win = open_win()
    scrollback.toggle(win, "default")
    assert.is_true(scrollback.is_open(win))
    scrollback.toggle(win, "default")
    assert.is_false(scrollback.is_open(win))
    vim.api.nvim_win_close(win, true)
  end)

  it("capture が nil のとき open は何もしない", function()
    package.loaded["amanoukihashi.tmux"] = tmux_stub(nil)
    local orig_buf, win = open_win()
    scrollback.open(win, "default")
    assert.equal(orig_buf, vim.api.nvim_win_get_buf(win))
    assert.is_false(scrollback.is_open(win))
    vim.api.nvim_win_close(win, true)
  end)

  it("ウィンドウを外から閉じると状態がクリアされる", function()
    local _, win = open_win()
    scrollback.open(win, "default")
    assert.is_true(scrollback.is_open(win))
    vim.api.nvim_win_close(win, true)
    assert.is_false(scrollback.is_open(win))
  end)
end)
