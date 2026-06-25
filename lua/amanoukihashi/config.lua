local M = {}

local defaults = {
  default_cmd = { "claude" },
  layout = "float",
  float = {
    width  = 0.45,
    height = 0.85,
    border = "rounded",
  },
  split = {
    width = 0.40,
  },
  list = {
    enabled = true,
    max_height = 8,
  },
}

local cfg = vim.deepcopy(defaults)

function M.setup(opts)
  cfg = M.normalize(opts)
end

function M.get()
  return cfg
end

function M.normalize(opts)
  return vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
