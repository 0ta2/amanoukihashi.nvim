local ctx = require("amanoukihashi.ctx")

describe("ctx", function()
  before_each(function()
    ctx._reset()
  end)

  it("get は win/buf/cwd/row/col を返す", function()
    local result = ctx.get()
    assert.is_number(result.win)
    assert.is_number(result.buf)
    assert.is_string(result.cwd)
    assert.is_number(result.row)
    assert.is_number(result.col)
  end)

  it("_win が nil のとき現在のウィンドウを返す", function()
    local cur = vim.api.nvim_get_current_win()
    local result = ctx.get()
    assert.equal(cur, result.win)
  end)

  it("_win がセットされていても現在のウィンドウが非ターミナルならそちらを使う", function()
    ctx.setup()
    local buf = vim.api.nvim_create_buf(false, true)
    -- open_win で WinLeave が発火し _win に元のウィンドウがキャッシュされる
    local new_win = vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = 20, height = 5, row = 0, col = 0, style = "minimal",
    })
    -- 現在のウィンドウ(new_win)は非ターミナル → _win より new_win を優先すべき
    local result = ctx.get()
    assert.equal(new_win, result.win)
    vim.api.nvim_win_close(new_win, true)
  end)
end)
