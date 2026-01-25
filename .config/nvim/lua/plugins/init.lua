return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "L3MON4D3/LuaSnip",
    config = function()
      -- En lua/plugins/init.lua, dentro de la config de LuaSnip:
      require("luasnip.loaders.from_vscode").lazy_load {
        paths = { vim.fn.stdpath "config" .. "/lua/custom/snippets" },
      }
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Añade esto dentro de la tabla de plugins en lua/plugins/init.lua
  {
    "Saghen/blink.cmp",
    opts = {
      snippets = { preset = "luasnip" },
    },
  },

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

  { import = "nvchad.blink.lazyspec" },

  {
    "mfussenegger/nvim-dap",
    -- Esto carga el plugin automáticamente al usar el comando o las teclas
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

      -- Registro manual de comandos
      vim.api.nvim_create_user_command("DapToggleBreakpoint", function()
        dap.toggle_breakpoint()
      end, {})
      vim.api.nvim_create_user_command("DapContinue", function()
        dap.continue()
      end, {})
      vim.api.nvim_create_user_command("DapTerminate", function()
        dap.terminate()
      end, {})

      -- Adaptador Bash
      dap.adapters.bashdb = {
        type = "executable",
        command = vim.fn.stdpath "data" .. "/mason/bin/bash-debug-adapter",
        args = { "start" },
      }

      require("dap-python").setup "python3"

      -- Configuración de depuración para Shell
      dap.configurations.sh = {
        {
          type = "bashdb",
          request = "launch",
          name = "Launch file",
          showDebugOutput = true,
          pathBashdb = vim.fn.stdpath "data" .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
          pathBashdbLib = vim.fn.stdpath "data" .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
          trace = true,
          file = "${file}",
          program = "${file}",
          cwd = "${workspaceFolder}",
          pathCat = "cat",
          pathBash = "/bin/bash",
          pathMkfifo = "mkfifo",
          pathPkill = "pkill",
          args = {},
          env = {},
          terminalKind = "integrated",
        },
      }

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
    end,
  },

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

  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = function()
      require("spectre").setup()
    end,
  },

  {
    "michaeljsmith/vim-indent-object",
    event = "VeryLazy",
  },
}
