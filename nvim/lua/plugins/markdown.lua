return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local config_path = vim.fn.stdpath("config") .. "/markdownlint.jsonc"
      local has_config = vim.uv.fs_stat(config_path) ~= nil

      opts.linters = opts.linters or {}

      if opts.linters["markdownlint-cli2"] then
        opts.linters["markdownlint-cli2"].args = has_config and { "--config", config_path, "--" } or { "--" }
      end
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if not vim.tbl_contains(opts.ensure_installed, "markdownlint-cli2") then
        table.insert(opts.ensure_installed, "markdownlint-cli2")
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      local config_path = vim.fn.stdpath("config") .. "/markdownlint.jsonc"
      local has_config = vim.uv.fs_stat(config_path) ~= nil

      opts.formatters = opts.formatters or {}
      opts.formatters.markdownlint_fix = {
        command = "markdownlint-cli2",
        args = has_config and { "--config", config_path, "--fix", "$FILENAME" } or { "--fix", "$FILENAME" },
        stdin = false,
      }

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.markdown = { "prettier", "markdownlint_fix" }
      opts.formatters_by_ft["markdown.mdx"] = { "prettier", "markdownlint_fix" }
    end,
  },
}
