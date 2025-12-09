local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    python = { "isort", "black" },
    json = { "prettier" },
    jsonc = { "prettier" },
    html = { "prettier" },
    typescript = { "prettier" },
    rust = { "rustfmt", lsp_format = "fallback" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    c = { "clang_format" },
    bash = { "shfmt", "shelcheck" },
    zsh = { "shfmt", "shelcheck" },
    sh = { "shfmt", "shelcheck" },
  },

  format_on_save = {
    timeout_ms = 1500,
    lsp_fallback = true,
  },
}
return options
