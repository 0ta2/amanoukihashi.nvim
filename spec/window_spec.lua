local window = require("amanoukihashi.window")

local float_cfg = {
  layout = "float",
  float  = { width = 0.45, height = 0.85, border = "rounded" },
  split  = { width = 0.40 },
}

local split_cfg = {
  layout = "split",
  float  = { width = 0.45, height = 0.85, border = "rounded" },
  split  = { width = 0.40 },
  list   = { enabled = true, max_height = 8 },
}

for _, cfg in ipairs({ float_cfg, split_cfg }) do
  describe("window (" .. cfg.layout .. ")", function()
    before_each(function()
      window._reset()
      require("amanoukihashi.scrollback")._reset()
    end)

    after_each(function()
      pcall(function()
        if window.is_open() then window.close() end
      end)
    end)

    it("初期状態では open していない", function()
      assert.is_false(window.is_open())
    end)

    it("open 後は is_open が true", function()
      local buf = vim.api.nvim_create_buf(false, true)
      window.open(buf, cfg)
      assert.is_true(window.is_open())
    end)

    it("close 後は is_open が false", function()
      local buf = vim.api.nvim_create_buf(false, true)
      window.open(buf, cfg)
      window.close()
      assert.is_false(window.is_open())
    end)

    it("open 後の winbar は空文字でない (dropbar 等が term:// を上書きしないように)", function()
      local buf = vim.api.nvim_create_buf(false, true)
      window.open(buf, cfg)
      assert.are_not.equal("", vim.wo[window.win()].winbar)
    end)

    it("swap で表示バッファが変わる", function()
      local buf1 = vim.api.nvim_create_buf(false, true)
      local buf2 = vim.api.nvim_create_buf(false, true)
      window.open(buf1, cfg)
      window.swap(buf2)
      assert.equal(buf2, vim.api.nvim_win_get_buf(window.win()))
    end)

    it("swap でスクロールバックが開いていても閉じてからバッファ差し替え", function()
      local buf1 = vim.api.nvim_create_buf(false, true)
      local buf2 = vim.api.nvim_create_buf(false, true)
      window.open(buf1, cfg)
      -- stub tmux so scrollback.open works without a real tmux session
      package.loaded["amanoukihashi.tmux"] = {
        session_name = function(n) return n end,
        capture = function() return "line1\nline2\n" end,
      }
      local scrollback = require("amanoukihashi.scrollback")
      scrollback.open(window.win(), "test")
      assert.is_true(scrollback.is_open(window.win()))
      -- swap should close scrollback first
      window.swap(buf2)
      assert.is_false(scrollback.is_open(window.win()))
      assert.equal(buf2, vim.api.nvim_win_get_buf(window.win()))
      package.loaded["amanoukihashi.tmux"] = nil
    end)

    it("open 済みのウィンドウを再 open すると古いウィンドウが閉じる", function()
      local buf1 = vim.api.nvim_create_buf(false, true)
      local buf2 = vim.api.nvim_create_buf(false, true)
      window.open(buf1, cfg)
      local old_win = window.win()
      window.open(buf2, cfg)
      assert.is_false(vim.api.nvim_win_is_valid(old_win))
      assert.is_true(window.is_open())
    end)

    it("open 後に WinEnter autocmd が登録されている", function()
      local buf = vim.api.nvim_create_buf(false, true)
      window.open(buf, cfg)
      local acs = vim.api.nvim_get_autocmds({
        group = "amanoukihashi_win_" .. window.win(),
        event = "WinEnter",
      })
      assert.equal(1, #acs)
    end)

    it("close 後に augroup がクリアされる", function()
      local buf = vim.api.nvim_create_buf(false, true)
      window.open(buf, cfg)
      local group_name = "amanoukihashi_win_" .. window.win()
      window.close()
      local ok = pcall(vim.api.nvim_get_autocmds, { group = group_name })
      assert.is_false(ok)
    end)
  end)
end

describe("window split + list panel", function()
  local window = require("amanoukihashi.window")
  local list   = require("amanoukihashi.list")

  before_each(function()
    window._reset()
    list._reset()
    require("amanoukihashi.scrollback")._reset()
    package.loaded["amanoukihashi.tmux"] = {
      list_sessions = function() return { { name = "a", active = true } } end,
      attention_status = function() return {} end,
    }
    package.loaded["amanoukihashi.config"] = {
      get = function() return split_cfg end,
    }
  end)

  after_each(function()
    pcall(function() if window.is_open() then window.close() end end)
    pcall(list.close)
    package.loaded["amanoukihashi.tmux"] = nil
    package.loaded["amanoukihashi.config"] = nil
  end)

  it("split で open すると一覧パネルも開く", function()
    local buf = vim.api.nvim_create_buf(false, true)
    window.open(buf, split_cfg)
    assert.is_true(list.is_open())
  end)

  it("close で一覧パネルも閉じる", function()
    local buf = vim.api.nvim_create_buf(false, true)
    window.open(buf, split_cfg)
    window.close()
    assert.is_false(list.is_open())
  end)

  it("float では一覧パネルを開かない", function()
    local buf = vim.api.nvim_create_buf(false, true)
    window.open(buf, float_cfg)
    assert.is_false(list.is_open())
  end)
end)
