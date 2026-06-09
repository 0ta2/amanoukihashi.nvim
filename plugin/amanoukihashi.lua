vim.api.nvim_create_user_command("AmanoukihashiToggle", function(opts)
  require("amanoukihashi").toggle(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

vim.api.nvim_create_user_command("AmanoukihashiList", function()
  require("amanoukihashi").list()
end, {})

vim.api.nvim_create_user_command("AmanoukihashiSend", function(opts)
  require("amanoukihashi").send(opts.args)
end, { nargs = "+", range = true })

vim.api.nvim_create_user_command("AmanoukihashiInsert", function(opts)
  require("amanoukihashi").insert(opts.args)
end, { nargs = "+", range = true })
