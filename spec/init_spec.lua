local init = require("amanoukihashi")

describe("amanoukihashi.toggle", function()
  local called_with
  local ui_input_stub

  before_each(function()
    called_with = nil
    ui_input_stub = nil
    package.loaded["amanoukihashi.toggle"] = {
      toggle = function(name, opts)
        called_with = { name = name, opts = opts }
      end,
      focus = function() end,
    }
    vim.ui.input = function(opts, cb)
      ui_input_stub = { opts = opts, cb = cb }
    end
    package.loaded["amanoukihashi"] = nil
    init = require("amanoukihashi")
  end)

  after_each(function()
    package.loaded["amanoukihashi.toggle"] = nil
    package.loaded["amanoukihashi"] = nil
  end)

  it("name あり → toggle.toggle を直接呼ぶ", function()
    init.toggle("my-session")

    assert.is_nil(ui_input_stub)
    assert.are.equal("my-session", called_with.name)
  end)

  it("name なし → vim.ui.input を呼ぶ", function()
    init.toggle()

    assert.is_not_nil(ui_input_stub)
    assert.are.equal("session name: ", ui_input_stub.opts.prompt)
  end)

  it("name なし → 入力後に toggle.toggle を呼ぶ", function()
    init.toggle()
    ui_input_stub.cb("new-session")

    assert.are.equal("new-session", called_with.name)
  end)

  it("name なし → 空文字入力では toggle.toggle を呼ばない", function()
    init.toggle()
    ui_input_stub.cb("")

    assert.is_nil(called_with)
  end)

  it("name なし → Esc (nil 入力) では toggle.toggle を呼ばない", function()
    init.toggle()
    ui_input_stub.cb(nil)

    assert.is_nil(called_with)
  end)
end)
