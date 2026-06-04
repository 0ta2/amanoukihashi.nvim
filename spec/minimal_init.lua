vim.opt.rtp:prepend(".")
vim.opt.rtp:prepend(
  os.getenv("PLENARY_PATH") or vim.fn.expand("~/.local/share/nvim/site/pack/core/opt/plenary.nvim")
)
