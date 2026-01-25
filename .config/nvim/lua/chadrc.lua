---@type ChadrcConfig
local M = {}

-- Opciones globales
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- ColorColumn sutil
-- Opción 1: Color sutil (Gris muy oscuro, casi negro)
-- vim.opt.colorcolumn = "80"
-- vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#2e3440" })

-- Opción 2: Color sutil (Gris muy oscuro, casi negro)
-- vim.opt.colorcolumn = "80"
-- vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1a1b26" })

-- Opción 3: Solo un cambio de brillo (Si tu fondo es #14141e)
vim.opt.colorcolumn = "80"
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1e222a" })

-- Opción 4: Solo un cambio de brillo (Si tu fondo es #14141e)
-- vim.opt.colorcolumn = "80"
-- vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1f1f2e" })

-- Agrupar comandos automáticos
local au_group = vim.api.nvim_create_augroup("CustomIndent", { clear = true })

-- Python: 4 espacios + Línea guía
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  group = au_group,
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "80" -- Solo aparece en Python
  end,
})

-- Bash: 2 espacios + Línea guía
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sh", "bash" },
  group = au_group,
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "80" -- Solo aparece en Bash
  end,
})

-- Limpieza automática al guardar (Tabs a Espacios)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  group = au_group,
  command = "silent! retab!",
})

-- Configuración de NvChad
M.base46 = {
  theme = "midnight_breeze",
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.nvdash = { load_on_startup = true }
M.ui = {
  tabufline = { lazyload = false },
}

M.nvimtree = {
  filters = {
    dotfiles = false,
    custom = { "^.git$", "^__pycache__$", "^.pytest_cache$", "%.pyc$" },
  },
  git = {
    enable = true,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M
