vim.api.nvim_create_user_command("AmanoukihashiToggle", function(opts)
  require("amanoukihashi").toggle(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

vim.api.nvim_create_user_command("AmanoukihashiList", function()
  require("amanoukihashi").list()
end, {})

vim.api.nvim_create_user_command("AmanoukihashiSend", function(opts)
  require("amanoukihashi").send(opts.args)
end, { nargs = "+", range = true })

vim.api.nvim_create_user_command("AmanoukihashiSubmit", function(opts)
  require("amanoukihashi").submit(opts.args)
end, { nargs = "+", range = true })

vim.api.nvim_create_user_command("AmanoukihashiFork", function(opts)
  require("amanoukihashi").fork(opts.args ~= "" and opts.args or nil)
end, { nargs = "?", desc = "Fork current Claude session" })
