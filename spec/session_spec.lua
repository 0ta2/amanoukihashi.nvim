local session = require("amanoukihashi.session")

describe("session", function()
  before_each(function()
    session._reset()
  end)

  it("current は初期状態で nil", function()
    assert.is_nil(session.current())
  end)

  it("set_current で名前を保存する", function()
    session.set_current("main")
    assert.equal("main", session.current())
  end)

  it("get で存在しない名前は nil を返す", function()
    assert.is_nil(session.get("nonexistent"))
  end)

  it("create_in_win でセッションが作成されバッファが有効", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = 40, height = 10, row = 0, col = 0,
    })
    local s = session.create_in_win("test", { "sh" }, win)
    assert.is_not_nil(s)
    assert.is_true(vim.api.nvim_buf_is_valid(s.buf))
    vim.api.nvim_win_close(win, true)
  end)

  it("create_in_win 後に get で同じセッションを返す", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = 40, height = 10, row = 0, col = 0,
    })
    session.create_in_win("test", { "sh" }, win)
    local s = session.get("test")
    assert.is_not_nil(s)
    assert.is_true(vim.api.nvim_buf_is_valid(s.buf))
    vim.api.nvim_win_close(win, true)
  end)
end)
