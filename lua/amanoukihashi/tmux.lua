local M = {}

local PREFIX = "amanoukihashi_"

local function tmux(args)
  vim.fn.system(vim.list_extend({ "tmux" }, args))
  return vim.v.shell_error == 0
end

function M.session_name(name)
  local cwd  = vim.fn.getcwd()
  local dir  = vim.fn.fnamemodify(cwd, ":t")
  local hash = string.sub(vim.fn.sha256(cwd), 1, 6)
  return PREFIX .. dir .. "_" .. hash .. "_" .. name
end

function M.session_exists(name)
  return tmux({ "has-session", "-t", M.session_name(name) })
end

function M.new_session_cmd(name, cmd)
  local sn = M.session_name(name)
  local shell_cmd = type(cmd) == "table"
    and table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " ")
    or cmd
  return string.format(
    "tmux new-session -d -s %s sh -lc %s \\; set-option -t %s status off \\; attach-session -t %s",
    vim.fn.shellescape(sn),
    vim.fn.shellescape(shell_cmd),
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

return M
