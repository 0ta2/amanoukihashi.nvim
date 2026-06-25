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
