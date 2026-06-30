local M = {}

local _win         = nil
local _normal_mode = false
local _cfg         = nil
local _showmode    = nil

local function float_opts(cfg)
  local w = math.max(math.floor(vim.o.columns * cfg.float.width), 80)
  local h = math.max(math.floor(vim.o.lines   * cfg.float.height), 10)
  return {
    relative = "editor",
    width    = w,
    height   = h,
    row      = math.floor((vim.o.lines   - h) / 2),
    col      = math.floor((vim.o.columns - w) / 2),
    style    = "minimal",
    border   = cfg.float.border,
  }
end

local function split_opts(cfg)
  local w = cfg.split.width
  return {
    win   = -1,
    split = "right",
    width = math.max(w <= 1 and math.floor(vim.o.columns * w) or w, 20),
    style = "minimal",
  }
end

function M.is_open()
  return _win ~= nil and vim.api.nvim_win_is_valid(_win)
end

function M.win()
  return _win
end

local function apply_win_opts(win)
  -- signcolumn/statuscolumn の左パディングはターミナルのリフロー計算と干渉するため無効化
  vim.wo[win].signcolumn     = "no"
  vim.wo[win].statuscolumn   = ""
  vim.wo[win].number         = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap           = false
  -- dropbar は winbar が "" (空文字) だと「未設定」と判定し TermOpen 等で自身の
  -- breadcrumb (term:// バッファ名) を上書きしてしまうため、空文字ではなく
  -- 無害な空白 1 文字を設定して dropbar の enable 判定 (winbar ~= '') を外す
  vim.wo[win].winbar         = " "
end

function M.open(buf, cfg)
  if M.is_open() then M.close() end
  _cfg = cfg
  local opts = cfg.layout == "split" and split_opts(cfg) or float_opts(cfg)
  _win = vim.api.nvim_open_win(buf, true, opts)
  apply_win_opts(_win)
  if cfg.layout == "split" then
    vim.wo[_win].winfixwidth = true
  end

  _showmode = vim.o.showmode
  vim.o.showmode = false

  local group = vim.api.nvim_create_augroup("amanoukihashi_win_" .. _win, { clear = true })

  local function fix_cursorline()
    if not M.is_open() then return end
    vim.wo[_win].cursorline = vim.fn.mode() ~= "t" and vim.api.nvim_get_current_win() == _win
  end

  vim.api.nvim_create_autocmd({ "TermLeave", "TermEnter" }, {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= _win then return end
      _normal_mode = vim.fn.mode() ~= "t"
      fix_cursorline()
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= _win then return end
      if require("amanoukihashi.scrollback").is_open(_win) then return end
      _showmode = vim.o.showmode
      vim.o.showmode = false
      fix_cursorline()
      if _normal_mode then
        vim.cmd("stopinsert")
      else
        vim.cmd("startinsert")
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= _win then return end
      if _showmode ~= nil then
        vim.o.showmode = _showmode
        _showmode = nil
      end
      fix_cursorline()
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group    = group,
    pattern  = tostring(_win),
    once     = true,
    callback = function()
      require("amanoukihashi.list").close()
      _win         = nil
      _normal_mode = false
      if _showmode ~= nil then
        vim.o.showmode = _showmode
        _showmode = nil
      end
      require("amanoukihashi.session").set_current(nil)
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group    = group,
    callback = function(ev)
      if not _win or not vim.api.nvim_win_is_valid(_win) then return end
      if vim.api.nvim_win_get_buf(_win) ~= ev.buf then return end
      vim.schedule(M.close)
    end,
  })

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group    = group,
    callback = function()
      if not M.is_open() then return end
      local ev = vim.v.event
      if ev and ev.windows and not vim.tbl_contains(ev.windows, _win) then return end
      if _cfg and _cfg.layout == "float" then
        pcall(vim.api.nvim_win_set_config, _win, float_opts(_cfg))
      end
      require("amanoukihashi.session").resize(_win)
    end,
  })

  local function apply_term_keymaps(term_buf)
    vim.keymap.set("t", "<C-q>", function()
      local name = require("amanoukihashi.session").current()
      if name then
        require("amanoukihashi.scrollback").toggle(_win, name)
      end
    end, { buffer = term_buf, silent = true, desc = "scrollback" })

    if cfg.layout == "split" then
      for _, dir in ipairs({ "h", "j", "k", "l" }) do
        vim.keymap.set("t", "<C-" .. dir .. ">", function()
          vim.cmd.wincmd(dir)
        end, { buffer = term_buf, silent = true })
      end
    end
  end

  -- 既存のターミナルバッファ（セッション再オープン時）は即時適用
  if vim.bo[buf].buftype == "terminal" then
    apply_term_keymaps(buf)
  end

  -- jobstart({ term = true }) はウィンドウバッファの更新を jobstart 完了後に行うため、
  -- TermOpen 発火時点では nvim_win_get_buf(_win) がまだ旧バッファを返す場合がある。
  -- vim.schedule で1イベントループ遅延させてバッファ更新を待つ。
  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function(ev)
      vim.schedule(function()
        if not _win or not vim.api.nvim_win_is_valid(_win) then return end
        if vim.api.nvim_win_get_buf(_win) == ev.buf then
          apply_win_opts(_win)
          apply_term_keymaps(ev.buf)
          require("amanoukihashi.list").refresh()
        end
      end)
    end,
  })

  if cfg.layout == "split" and cfg.list and cfg.list.enabled then
    require("amanoukihashi.list").open(_win, cfg)
  end

  vim.cmd("startinsert")
end

function M.close()
  if M.is_open() then
    require("amanoukihashi.list").close()
    require("amanoukihashi.scrollback").close(_win)
    _normal_mode = false
    pcall(vim.api.nvim_del_augroup_by_name, "amanoukihashi_win_" .. _win)
    vim.api.nvim_win_close(_win, true)
  end
  _win = nil
  if _showmode ~= nil then
    vim.o.showmode = _showmode
    _showmode = nil
  end
end

function M.swap(buf)
  if M.is_open() then
    require("amanoukihashi.scrollback").close(_win)
    vim.api.nvim_win_set_buf(_win, buf)
    apply_win_opts(_win)
    require("amanoukihashi.session").resize(_win)
    vim.cmd("startinsert")
  end
end

function M._reset()
  if _win then
    pcall(vim.api.nvim_del_augroup_by_name, "amanoukihashi_win_" .. _win)
  end
  _win         = nil
  _normal_mode = false
  _cfg         = nil
  if _showmode ~= nil then
    vim.o.showmode = _showmode
    _showmode = nil
  end
end

return M
