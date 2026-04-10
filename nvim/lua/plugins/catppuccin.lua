-- Prefer COLOR_MODE env; else on macOS follow system appearance (deferred); else default dark (macchiato).
-- opts never call vim.fn.system so startup does not block on Nix/sandbox.
local function catppuccin_flavour_sync()
  local mode = os.getenv("COLOR_MODE")
  if mode == "light" then
    return "latte"
  end
  if mode == "dark" then
    return "macchiato"
  end
  return "macchiato"
end

local function catppuccin_flavour_from_mac()
  if vim.fn.has("mac") ~= 1 then
    return nil
  end
  local ok, out = pcall(function()
    return vim.fn.trim(vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }))
  end)
  if ok and out == "Dark" then
    return "macchiato"
  end
  if ok and (out == "Light" or out == "") then
    return "latte"
  end
  return nil
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = function()
      return {
        flavour = catppuccin_flavour_sync(),
        transparent_background = true,
      }
    end,
    config = function(_, opts)
      vim.g.catppuccin_flavour = opts.flavour
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")

      -- Defer macOS appearance check; re-apply if flavour differs.
      if os.getenv("COLOR_MODE") == nil and vim.fn.has("mac") == 1 then
        vim.defer_fn(function()
          local mac_flavour = catppuccin_flavour_from_mac()
          if mac_flavour and mac_flavour ~= (vim.g.catppuccin_flavour or opts.flavour) then
            vim.g.catppuccin_flavour = mac_flavour
            require("catppuccin").setup(vim.tbl_extend("force", opts, { flavour = mac_flavour }))
            vim.cmd.colorscheme("catppuccin")
          end
        end, 0)
      end

      -- Toggle light/dark and reload (optional in-session switch)
      vim.api.nvim_create_user_command("CatppuccinToggle", function()
        local current = vim.g.catppuccin_flavour or "macchiato"
        local next_flavour = (current == "macchiato") and "latte" or "macchiato"
        vim.g.catppuccin_flavour = next_flavour
        require("catppuccin").setup(vim.tbl_extend("force", opts, { flavour = next_flavour }))
        vim.cmd.colorscheme("catppuccin")
        vim.notify("Catppuccin: " .. next_flavour, vim.log.levels.INFO)
      end, {})
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
