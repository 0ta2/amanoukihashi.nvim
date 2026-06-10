local init = require("amanoukihashi")

describe("amanoukihashi.toggle", function()
  local called_with
  local ui_input_stub
  local ui_select_stub

  before_each(function()
    called_with    = nil
    ui_input_stub  = nil
    ui_select_stub = nil
    package.loaded["amanoukihashi.toggle"] = {
      toggle = function(name, opts)
        called_with = { name = name, opts = opts }
      end,
      focus = function() end,
    }
    package.loaded["amanoukihashi.tmux"] = {
      list_sessions = function() return {} end,
    }
    vim.ui.input = function(opts, cb)
      ui_input_stub = { opts = opts, cb = cb }
    end
    vim.ui.select = function(items, opts, cb)
      ui_select_stub = { items = items, opts = opts, cb = cb }
    end
    package.loaded["amanoukihashi"] = nil
    init = require("amanoukihashi")
  end)

  after_each(function()
    package.loaded["amanoukihashi.toggle"] = nil
    package.loaded["amanoukihashi.tmux"]   = nil
    package.loaded["amanoukihashi"] = nil
  end)

  it("name あり → toggle.toggle を直接呼ぶ", function()
    init.toggle("my-session")

    assert.is_nil(ui_input_stub)
    assert.are.equal("my-session", called_with.name)
  end)

  it("name なし + セッション 0 個 → vim.ui.input を呼ぶ", function()
    init.toggle()

    assert.is_not_nil(ui_input_stub)
    assert.are.equal("session name: ", ui_input_stub.opts.prompt)
  end)

  it("name なし + セッション 0 個 → 入力後に toggle.toggle を呼ぶ", function()
    init.toggle()
    ui_input_stub.cb("new-session")

    assert.are.equal("new-session", called_with.name)
  end)

  it("name なし + セッション 0 個 → 空文字入力では toggle.toggle を呼ばない", function()
    init.toggle()
    ui_input_stub.cb("")

    assert.is_nil(called_with)
  end)

  it("name なし + セッション 0 個 → Esc では toggle.toggle を呼ばない", function()
    init.toggle()
    ui_input_stub.cb(nil)

    assert.is_nil(called_with)
  end)

  it("name なし + セッションあり → vim.ui.select を呼ぶ（末尾に + new を含む）", function()
    local sessions = { { name = "A", active = false }, { name = "B", active = true } }
    package.loaded["amanoukihashi.tmux"] = { list_sessions = function() return sessions end }
    package.loaded["amanoukihashi"] = nil
    init = require("amanoukihashi")

    init.toggle()

    assert.is_nil(ui_input_stub)
    assert.is_not_nil(ui_select_stub)
    assert.are.equal(3, #ui_select_stub.items)
    assert.are.equal("+ new session", ui_select_stub.opts.format_item(ui_select_stub.items[3]))
    assert.are.equal("○ A", ui_select_stub.opts.format_item(ui_select_stub.items[1]))
  end)

  it("list で + new を選ぶ → vim.ui.input を呼ぶ", function()
    local sessions = { { name = "A", active = false } }
    package.loaded["amanoukihashi.tmux"] = { list_sessions = function() return sessions end }
    package.loaded["amanoukihashi"] = nil
    init = require("amanoukihashi")

    init.list()
    local new_item = ui_select_stub.items[#ui_select_stub.items]
    ui_select_stub.cb(new_item)

    assert.is_not_nil(ui_input_stub)
    assert.are.equal("session name: ", ui_input_stub.opts.prompt)
  end)

  it("list で + new を選んで名前入力 → toggle.toggle を呼ぶ", function()
    local sessions = { { name = "A", active = false } }
    package.loaded["amanoukihashi.tmux"] = { list_sessions = function() return sessions end }
    package.loaded["amanoukihashi"] = nil
    init = require("amanoukihashi")

    init.list()
    local new_item = ui_select_stub.items[#ui_select_stub.items]
    ui_select_stub.cb(new_item)
    ui_input_stub.cb("new-session")

    assert.are.equal("new-session", called_with.name)
  end)

  it("name なし + セッションあり + opts 指定 → list の + new 経由でも opts が toggle.toggle に渡る", function()
    local sessions = { { name = "A", active = false } }
    package.loaded["amanoukihashi.tmux"] = { list_sessions = function() return sessions end }
    package.loaded["amanoukihashi"] = nil
    init = require("amanoukihashi")

    local opts = { cmd = { "bash" } }
    init.toggle(nil, opts)
    local new_item = ui_select_stub.items[#ui_select_stub.items]
    ui_select_stub.cb(new_item)
    ui_input_stub.cb("new-session")

    assert.are.equal("new-session", called_with.name)
    assert.are.equal(opts, called_with.opts)
  end)

  it("name なし + ウィンドウ開 → session.current() で即 toggle.toggle を呼ぶ", function()
    package.loaded["amanoukihashi.window"]  = { is_open = function() return true end }
    package.loaded["amanoukihashi.session"] = { current = function() return "running" end }

    init.toggle()

    assert.is_nil(ui_input_stub)
    assert.are.equal("running", called_with.name)

    package.loaded["amanoukihashi.window"]  = nil
    package.loaded["amanoukihashi.session"] = nil
  end)

  it("name なし + ウィンドウ開 + current nil + セッション 0 個 → vim.ui.input を呼ぶ", function()
    package.loaded["amanoukihashi.window"]  = { is_open = function() return true end }
    package.loaded["amanoukihashi.session"] = { current = function() return nil end }

    init.toggle()

    assert.is_not_nil(ui_input_stub)
    assert.is_nil(ui_select_stub)

    package.loaded["amanoukihashi.window"]  = nil
    package.loaded["amanoukihashi.session"] = nil
  end)
end)
