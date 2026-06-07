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

  describe("new_session_cmd", function()
    local orig_shellescape

    before_each(function()
      orig_shellescape = vim.fn.shellescape
      vim.fn.shellescape = function(s) return "'" .. s .. "'" end
    end)

    after_each(function()
      vim.fn.shellescape = orig_shellescape
    end)

    it("cmd をテーブルで渡すと sh -lc に正しく渡る", function()
      local result = tmux.new_session_cmd("default", { "bash" }, nil, nil)
      assert.truthy(result:find("sh -lc", 1, true))
      assert.truthy(result:find("bash", 1, true))
      assert.truthy(result:find("test_session", 1, true))
    end)

    it("複数要素の cmd は各要素が引数境界を保って結合される", function()
      local result = tmux.new_session_cmd("default", { "bash", "-c", "echo hello" }, nil, nil)
      assert.truthy(result:find("sh -lc", 1, true))
      assert.truthy(result:find("bash", 1, true))
      assert.truthy(result:find("echo hello", 1, true))
    end)

    it("width/height を指定するとサイズフラグが含まれる", function()
      local result = tmux.new_session_cmd("default", { "bash" }, 80, 24)
      assert.truthy(result:find("-x 80 -y 24", 1, true))
    end)

    it("width/height が nil のときサイズフラグが含まれない", function()
      local result = tmux.new_session_cmd("default", { "bash" }, nil, nil)
      assert.falsy(result:find("-x ", 1, true))
      assert.falsy(result:find("-y ", 1, true))
    end)

    it("文字列の cmd を渡すとエラーになる", function()
      assert.has_error(function()
        tmux.new_session_cmd("default", "bash", nil, nil)
      end)
    end)
  end)
end)
