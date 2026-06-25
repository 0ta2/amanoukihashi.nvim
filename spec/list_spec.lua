local list = require("amanoukihashi.list")
local H = dofile(debug.getinfo(1, "S").source:sub(2):gsub("[^/]+$", "") .. "helpers.lua")

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

  it("needs_attention が true の行には ⚠ を前置する", function()
    local lines = list.render_lines({
      { name = "a", active = true, needs_attention = true },
      { name = "b", active = false },
    })
    assert.same({ "⚠ ● a", "○ b", "+ new session" }, lines)
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
  local anchor

  before_each(function()
    list._reset()
    package.loaded["amanoukihashi.tmux"] = {
      list_sessions = function()
        return { { name = "a", active = true }, { name = "b", active = false } }
      end,
      attention_status = function() return {} end,
    }
    local _, win = H.open_anchor_win()
    anchor = win
  end)

  after_each(function()
    pcall(list.close)
    pcall(vim.api.nvim_win_close, anchor, true)
    package.loaded["amanoukihashi.tmux"] = nil
  end)

  it("open でアンカーの上に一覧ウィンドウが開く", function()
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    assert.is_true(list.is_open())
    -- フォーカスはアンカーのまま（enter=false）
    assert.equal(anchor, vim.api.nvim_get_current_win())
  end)

  it("一覧の内容は render_lines と一致する", function()
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    local buf = vim.api.nvim_win_get_buf(list._win_for_test())
    assert.same({ "● a", "○ b", "+ new session" },
      vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("close で閉じる", function()
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    list.close()
    assert.is_false(list.is_open())
  end)

  it("refresh でセッション一覧が更新される", function()
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    -- セッションが増えた状態に差し替え
    package.loaded["amanoukihashi.tmux"] = {
      list_sessions = function()
        return {
          { name = "a", active = false },
          { name = "b", active = true },
          { name = "c", active = false },
        }
      end,
      attention_status = function() return {} end,
    }
    list.refresh()
    local buf = vim.api.nvim_win_get_buf(list._win_for_test())
    assert.same({ "○ a", "● b", "○ c", "+ new session" },
      vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("open 時に attention_status の結果が一覧に反映される", function()
    package.loaded["amanoukihashi.tmux"].attention_status = function()
      return { b = true }
    end
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    local buf = vim.api.nvim_win_get_buf(list._win_for_test())
    assert.same({ "● a", "⚠ ○ b", "+ new session" },
      vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("refresh 時に attention_status の結果が再反映される", function()
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    package.loaded["amanoukihashi.tmux"].attention_status = function()
      return { a = true }
    end
    list.refresh()
    local buf = vim.api.nvim_win_get_buf(list._win_for_test())
    assert.same({ "⚠ ● a", "○ b", "+ new session" },
      vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("閉じている時の refresh は no-op", function()
    assert.has_no.errors(function() list.refresh() end)
  end)

  it("非 active 行で <CR> すると toggle.focus が呼ばれる", function()
    local focused
    package.loaded["amanoukihashi.toggle"] = { focus = function(n) focused = n end }
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    -- 行2 = "○ b"（非 active）
    vim.api.nvim_win_set_cursor(list._win_for_test(), { 2, 0 })
    list._on_enter()
    assert.equal("b", focused)
    package.loaded["amanoukihashi.toggle"] = nil
  end)

  it("active 行で <CR> するとアンカーにフォーカスが戻り toggle.focus は呼ばれない", function()
    local called = false
    package.loaded["amanoukihashi.toggle"] = { focus = function() called = true end }
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    vim.api.nvim_set_current_win(list._win_for_test())
    vim.api.nvim_win_set_cursor(list._win_for_test(), { 1, 0 }) -- "● a"
    list._on_enter()
    assert.is_false(called)
    assert.equal(anchor, vim.api.nvim_get_current_win())
    package.loaded["amanoukihashi.toggle"] = nil
  end)

  it("new 行で <CR> すると入力名で toggle.focus が呼ばれる", function()
    local focused
    package.loaded["amanoukihashi.toggle"] = { focus = function(n) focused = n end }
    local orig_input = vim.ui.input
    vim.ui.input = function(_, cb) cb("newsess") end
    list.open(anchor, { list = { enabled = true, max_height = 8 } })
    vim.api.nvim_win_set_cursor(list._win_for_test(), { 3, 0 }) -- "+ new session"
    list._on_enter()
    assert.equal("newsess", focused)
    vim.ui.input = orig_input
    package.loaded["amanoukihashi.toggle"] = nil
  end)
end)
