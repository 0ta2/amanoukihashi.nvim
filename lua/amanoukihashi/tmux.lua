local M = {}

local PREFIX = "amanoukihashi_"

local function tmux(args)
  local out = vim.fn.system(vim.list_extend({ "tmux" }, args))
  if vim.v.shell_error ~= 0 and out ~= "" then
    vim.notify("amanoukihashi(tmux): " .. out, vim.log.levels.DEBUG)
  end
  return vim.v.shell_error == 0
end

function M.session_name(name)
  local cwd  = vim.fn.getcwd()
  local dir  = vim.fn.fnamemodify(cwd, ":t"):gsub("[^%w%-]", "_")
  local hash = string.sub(vim.fn.sha256(cwd), 1, 6)
  return PREFIX .. dir .. "_" .. hash .. "_" .. name:gsub("[^%w%-]", "_")
end

function M.session_exists(name)
  return tmux({ "has-session", "-t", M.session_name(name) })
end

function M.new_session_cmd(name, cmd, width, height)
  assert(type(cmd) == "table", "cmd must be a table of strings")
  local sn = M.session_name(name)
  -- 要素ごとの shellescape で引数境界を保護し、全体の shellescape で sh -lc の引数として保護する
  local shell_cmd = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " ")
  local size = (width and height)
    and string.format("-x %d -y %d ", width, height)
    or ""
  return string.format(
    "tmux new-session -d %s-s %s sh -lc %s \\; set-option -t %s status off \\; attach-session -t %s",
    size,
    vim.fn.shellescape(sn),
    vim.fn.shellescape(shell_cmd),  -- 結合済みの要素列を sh -lc の引数として保護する
    vim.fn.shellescape(sn),
    vim.fn.shellescape(sn)
  )
end

function M.join_session_cmd(name)
  return "tmux attach-session -t " .. vim.fn.shellescape(M.session_name(name))
end

function M.kill_session(name)
  tmux({ "kill-session", "-t", M.session_name(name) })
end

function M.capture(name)
  local sn = M.session_name(name)
  local out = vim.fn.system({ "tmux", "capture-pane", "-p", "-S", "-", "-t", sn })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

return M
