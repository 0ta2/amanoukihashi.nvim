local M = {}

local _win         = nil
local _normal_mode = false
local _cfg         = nil

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

function M.open(buf, cfg)
  if M.is_open() then M.close() end
  _cfg = cfg
  local opts = cfg.layout == "split" and split_opts(cfg) or float_opts(cfg)
  _win = vim.api.nvim_open_win(buf, true, opts)
  if cfg.layout == "split" then
    vim.wo[_win].winfixwidth    = true
    vim.wo[_win].signcolumn     = "no"
    vim.wo[_win].statuscolumn   = ""
    vim.wo[_win].number         = false
    vim.wo[_win].relativenumber = false
    vim.wo[_win].wrap           = false
  end

  local group = vim.api.nvim_create_augroup("amanoukihashi_win_" .. _win, { clear = true })

  vim.api.nvim_create_autocmd("TermLeave", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= _win then return end
      _normal_mode = vim.fn.mode() ~= "t"
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= _win then return end
      if _normal_mode then
        vim.cmd("stopinsert")
      else
        vim.cmd("startinsert")
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group    = group,
    pattern  = tostring(_win),
    once     = true,
    callback = function()
      _win         = nil
      _normal_mode = false
      require("amanoukihashi.session").set_current(nil)
      vim.api.nvim_del_augroup_by_id(group)
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

  if cfg.layout == "split" then
    for _, dir in ipairs({ "h", "j", "k", "l" }) do
      vim.keymap.set("t", "<C-" .. dir .. ">", function()
        vim.cmd.wincmd(dir)
      end, { buffer = buf, silent = true })
    end
  end

  vim.cmd("startinsert")
end

function M.close()
  if M.is_open() then
    _normal_mode = false
    pcall(vim.api.nvim_del_augroup_by_name, "amanoukihashi_win_" .. _win)
    vim.api.nvim_win_close(_win, true)
  end
  _win = nil
end

function M.swap(buf)
  if M.is_open() then
    vim.api.nvim_win_set_buf(_win, buf)
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
end

return M
