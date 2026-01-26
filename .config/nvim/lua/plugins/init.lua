return {
  -- Formateo de código
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- Configuración de Snippets
  {
    "L3MON4D3/LuaSnip",
    lazy = false,
    config = function()
      require "nvchad.configs.luasnip"

      -- Usamos .load en lugar de .lazy_load para forzar la lectura
      require("luasnip.loaders.from_vscode").load {
        paths = { vim.fn.expand "~/.config/nvim/snippets" },
      }
    end,
  },
  -- Motor de autocompletado (Blink.cmp)
  {
    "Saghen/blink.cmp",
    dependencies = { { import = "nvchad.blink.lazyspec" } },
    opts = {
      snippets = {
        preset = "luasnip",
      },
      sources = {
        -- Prioridad de fuentes: LSP y Snippets primero
        default = { "lsp", "snippets", "buffer", "path" },
      },
      completion = {
        menu = {
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
          },
        },
      },
    },
  },

  -- Configuración de LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Gestor de herramientas (LSP, Linters, Debuggers)
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "ruff",
        "black",
        "isort",
        "bash-language-server",
        "shellcheck",
        "shfmt",
        "json-lsp",
        "jq",
        "debugpy",
        "bash-debug-adapter",
      },
    },
  },

  -- Depuración (DAP)
  {
    "mfussenegger/nvim-dap",
    cmd = { "DapToggleBreakpoint", "DapContinue", "DapTerminate" },
    keys = { "<leader>db", "<leader>dc" },
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require "dap"
      local ui = require "dapui"
      ui.setup()

      require("dap-python").setup "python3"

      -- Adaptador para Bash
      dap.adapters.bashdb = {
        type = "executable",
        command = vim.fn.stdpath "data" .. "/mason/bin/bash-debug-adapter",
        args = { "start" },
      }

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
    end,
  },

  -- Resaltado de sintaxis
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "python",
        "bash",
        "json",
        "kdl",
      },
    },
  },

  -- Búsqueda y reemplazo avanzado
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = function()
      require("spectre").setup()
    end,
  },

  -- Objetos de texto para indentación
  {
    "michaeljsmith/vim-indent-object",
    event = "VeryLazy",
  },
}
