vim.api.nvim_create_user_command("AmanoukihashiToggle", function(opts)
  require("amanoukihashi").toggle(opts.args ~= "" and opts.args or "default")
end, { nargs = "?" })

vim.api.nvim_create_user_command("AmanoukihashiList", function()
  require("amanoukihashi").list()
end, {})
