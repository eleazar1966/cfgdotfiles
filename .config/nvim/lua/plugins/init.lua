return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
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
}
