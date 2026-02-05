---@type ChadrcConfig
local M = {}

-- =============================================================================
-- OPCIONES GLOBALES
-- =============================================================================
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- ColorColumn sutil para guías de estilo
vim.opt.colorcolumn = "80"
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1e222a" })

-- =============================================================================
-- AUTOCOMANDOS DE INDENTACIÓN (Terminal HKA v39.0)
-- =============================================================================
local au_group = vim.api.nvim_create_augroup("CustomIndent", { clear = true })

-- Configuración para Python (4 espacios)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  group = au_group,
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "80"
  end,
})

-- Configuración para Bash/Shell (Sincronizado a 2 espacios)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sh", "bash" },
  group = au_group,
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- =============================================================================
-- CONFIGURACIÓN DE UI (NVCHAD)
-- =============================================================================
M.base46 = {
  theme = "midnight_breeze",
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.nvdash = { load_on_startup = true }

M.nvimtree = {
  filters = {
    dotfiles = false,
    custom = { "^.git$", "^__pycache__$", "^.pytest_cache$", "%.pyc$" },
  },
  git = { enable = true },
  renderer = {
    highlight_git = true,
    icons = { show = { git = true } },
  },
}

M.ui = {
  tabufline = { lazyload = false },
  statusline = {
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "cursor", "cwd" },
    modules = {
      cursor = function()
        local line = vim.fn.line "."
        local total_line = vim.fn.line "$"
        local col = vim.fn.virtcol "."

        local color = "%#St_LspHintsBg#"
        if total_line > 1000 then
          color = "%#St_LspErrorBg#"
        elseif total_line > 750 then
          color = "%#St_LspWarningBg#"
        elseif total_line > 500 then
          color = "%#St_LspInfoBg#"
        end

        return color .. "  " .. line .. ":" .. col .. " "
      end,
    },
  },
}

return M
