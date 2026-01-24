local nvlsp = require "nvchad.configs.lspconfig"
local lspconfig = require "lspconfig"

lspconfig.pyright.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        typeCheckingMode = "basic", -- Cambia a "strict" para máxima sensibilidad
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
      },
    },
  },
}

lspconfig.jsonls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
}

lspconfig.bashls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities, -- Esto es lo que activa el autocompletado
  filetypes = { "sh", "bash" },
}
