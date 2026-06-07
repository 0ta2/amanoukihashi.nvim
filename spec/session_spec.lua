local session = require("amanoukihashi.session")
local H        = dofile(debug.getinfo(1, "S").source:sub(2):gsub("[^/]+$", "") .. "helpers.lua")

-- tmux モジュールをスタブして CI でも tmux なしでテストできるようにする
local function tmux_stub(session_exists)
  return {
    session_exists  = function() return session_exists end,
    new_session_cmd = function() return { "sh" } end,
    join_session_cmd= function() return "sh" end,
    session_name    = function(n) return n end,
    kill_session    = function() end,
  }
end

local open_win = H.open_win

describe("session", function()
  before_each(function()
    session._reset()
    package.loaded["amanoukihashi.tmux"] = tmux_stub(false)
  end)

  after_each(function()
    package.loaded["amanoukihashi.tmux"] = nil
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

  it("open でセッションが作成されバッファが有効", function()
    local _, win = open_win()
    local s = session.open("test", { "sh" }, win)
    assert.is_not_nil(s)
    assert.is_true(vim.api.nvim_buf_is_valid(s.buf))
    vim.api.nvim_win_close(win, true)
  end)

  it("open 後に get で同じセッションを返す", function()
    local _, win = open_win()
    session.open("test", { "sh" }, win)
    local s = session.get("test")
    assert.is_not_nil(s)
    assert.is_true(vim.api.nvim_buf_is_valid(s.buf))
    vim.api.nvim_win_close(win, true)
  end)

  it("tmux セッション既存時は join_session_cmd を使う", function()
    package.loaded["amanoukihashi.tmux"] = tmux_stub(true)
    local called_with = nil
    local orig = vim.fn.jobstart
    vim.fn.jobstart = function(cmd, opts)
      called_with = cmd
      return orig(cmd, opts)
    end

    local _, win = open_win()
    local ok, err = pcall(session.open, "existing", { "sh" }, win)
    vim.fn.jobstart = orig

    assert.is_true(ok, err)
    assert.equal("sh", called_with)
    vim.api.nvim_win_close(win, true)
  end)

  it("open 2回目は既存バッファを再利用する", function()
    local _, win = open_win()
    local s1 = session.open("test", { "sh" }, win)
    local s2 = session.open("test", { "sh" }, win)
    assert.equal(s1.buf, s2.buf)
    assert.equal(s1.job_id, s2.job_id)
    vim.api.nvim_win_close(win, true)
  end)

  it("kill でセッションがテーブルから除去される", function()
    local _, win = open_win()
    session.open("test", { "sh" }, win)
    assert.is_not_nil(session.get("test"))
    session.kill("test")
    assert.is_nil(session.get("test"))
    -- kill がバッファを削除するとウィンドウも閉じるため pcall で保護する
    pcall(vim.api.nvim_win_close, win, true)
  end)
end)
