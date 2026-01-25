local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    -- isort ordena los imports y black formatea el código
    python = { "isort", "black" },
    bash = { "shfmt" },
    sh = { "shfmt" },
    json = { "jq" },
  },

  -- Personalización de argumentos
  formatters = {
    shfmt = {
      -- Cambiado a 2 para coincidir con tu configuración de Neovim
      prepend_args = { "-i", "2", "-ci" },
    },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
