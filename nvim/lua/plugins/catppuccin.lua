return {
  {
    "tinted-theming/tinted-vim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.tinted_colorspace = 256
      vim.cmd.colorscheme("base16-catppuccin-macchiato")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "base16-catppuccin-macchiato" },
  },
}
