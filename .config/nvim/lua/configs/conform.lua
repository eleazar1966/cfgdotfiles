local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    bash = { "shfmt" },
    sh = { "shfmt" },
    json = { "jq" },
    kdl = { "kdlfmt" },
  },

  formatters = {
    shfmt = {
      prepend_args = { "-i", "2", "-ci" },
    },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
