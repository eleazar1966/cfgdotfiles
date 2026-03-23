local nvlsp = require "nvchad.configs.lspconfig"
local lspconfig = require "lspconfig"

local servers = { "pyright", "bashls", "jsonls", "lua_ls", "kdl_ls" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end
