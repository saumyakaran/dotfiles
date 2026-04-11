local theme_file = vim.fn.expand("~/dotfiles/theme/current")
local last_scheme = ""

local function load_current_theme()
  if vim.fn.filereadable(theme_file) ~= 1 then
    return
  end
  local scheme = vim.fn.trim(vim.fn.readfile(theme_file)[1] or "")
  if scheme == "" or scheme == last_scheme then
    return
  end
  last_scheme = scheme
  local ok, _ = pcall(vim.cmd.colorscheme, scheme)
  if not ok then
    vim.notify("Theme not found: " .. scheme, vim.log.levels.WARN)
  end
end

return {
  {
    "tinted-theming/tinted-vim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.tinted_colorspace = 256
      load_current_theme()

      local timer = vim.uv.new_timer()
      timer:start(2000, 2000, vim.schedule_wrap(function()
        load_current_theme()
      end))
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = function()
      local scheme = "base16-catppuccin-macchiato"
      local f = vim.fn.expand("~/dotfiles/theme/current")
      if vim.fn.filereadable(f) == 1 then
        scheme = vim.fn.trim(vim.fn.readfile(f)[1] or scheme)
      end
      return { colorscheme = scheme }
    end,
  },
}
