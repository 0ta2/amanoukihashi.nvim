local M = {}

function M.setup(opts)
  require("amanoukihashi.config").setup(opts)
end

function M.toggle(name, opts)
  require("amanoukihashi.toggle").toggle(name, opts)
end

return M
