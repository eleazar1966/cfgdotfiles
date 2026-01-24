local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    python = { "isort", "black" },
    bash = { "shfmt" },
    sh = { "shfmt" },
    json = { "jq" },
  },

  -- Personalización de argumentos
  formatters = {
    shfmt = {
      prepend_args = { "-i", "4" }, -- "-i 4" configura 4 espacios de sangría
    },
  },

  format_on_save = {
    --   -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
