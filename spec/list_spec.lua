local list = require("amanoukihashi.list")

describe("list.render_lines", function()
  it("active は ●、非 active は ○ を前置し末尾に new 行を足す", function()
    local lines = list.render_lines({
      { name = "a", active = true },
      { name = "b", active = false },
    })
    assert.same({ "● a", "○ b", "+ new session" }, lines)
  end)

  it("セッション 0 件でも new 行だけ返す", function()
    assert.same({ "+ new session" }, list.render_lines({}))
  end)
end)

describe("list.action_for", function()
  local sessions = { { name = "a", active = true }, { name = "b", active = false } }

  it("active 行は refocus", function()
    local action = list.action_for(1, sessions)
    assert.equal("refocus", action)
  end)

  it("非 active 行は switch と対象セッション", function()
    local action, s = list.action_for(2, sessions)
    assert.equal("switch", action)
    assert.equal("b", s.name)
  end)

  it("new 行（末尾）は new", function()
    assert.equal("new", list.action_for(3, sessions))
  end)
end)

describe("list window", function()
  local list = require("amanoukihashi.list")

  before_each(function()
    list._reset()
    package.loaded["amanoukihashi.tmux"] = {
      list_sessions = function()
        return { { name = "a", active = true }, { name = "b", active = false } }
      end,
    }
    package.loaded["amanoukihashi.config"] = {
      get = function() return { list = { enabled = true, max_height = 8 } } end,
    }
  end)

  after_each(function()
    pcall(list.close)
    package.loaded["amanoukihashi.tmux"] = nil
    package.loaded["amanoukihashi.config"] = nil
  end)

  it("open でアンカーの上に一覧ウィンドウが開く", function()
    local abuf = vim.api.nvim_create_buf(false, true)
    local anchor = vim.api.nvim_open_win(abuf, true, {
      win = -1, split = "right", width = 40, style = "minimal",
    })
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    assert.is_true(list.is_open())
    -- フォーカスはアンカーのまま（enter=false）
    assert.equal(anchor, vim.api.nvim_get_current_win())
    pcall(vim.api.nvim_win_close, anchor, true)
  end)

  it("一覧の内容は render_lines と一致する", function()
    local abuf = vim.api.nvim_create_buf(false, true)
    local anchor = vim.api.nvim_open_win(abuf, true, {
      win = -1, split = "right", width = 40, style = "minimal",
    })
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    local buf = vim.api.nvim_win_get_buf(list._win_for_test())
    assert.same({ "● a", "○ b", "+ new session" },
      vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    pcall(vim.api.nvim_win_close, anchor, true)
  end)

  it("close で閉じる", function()
    local abuf = vim.api.nvim_create_buf(false, true)
    local anchor = vim.api.nvim_open_win(abuf, true, {
      win = -1, split = "right", width = 40, style = "minimal",
    })
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    list.close()
    assert.is_false(list.is_open())
    pcall(vim.api.nvim_win_close, anchor, true)
  end)
end)
