-- filepath: custom/plugins/init.lua
return {
  -- Formateo (Conform)
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",


  },

  -- Linter (Validación extra para Python/Bash)
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost" },
    config = function()
      local lint = require "lint"
      lint.linters_by_ft = {
        python = { "flake8" },
        bash = { "shellcheck" },
        json = { "jsonlint" },
      }
    end,
  },

  -- LSP Principal
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Mason: Instalación automática
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "black",
        "isort",
        "flake8",
        "bash-language-server",
        "shellcheck",
        "shfmt",
        "json-lsp",
        "jq",
        "stylua",
      },
    },
  },

  -- Colorizer (Corregido para cargar en FilePost)
  {
    "NvChad/nvim-colorizer.lua",
    event = "User FilePost",
    config = function()
      require("colorizer").setup {
        user_default_options = {
          mode = "background",
          names = false,
        },
      }
    end,
  },

  -- Spectre (Búsqueda)
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
  },
}
