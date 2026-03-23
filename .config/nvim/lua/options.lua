-- filepath: custom/options.lua
require "nvchad.options"

local opt = vim.opt

opt.relativenumber = true
opt.number = true
-- Esto es vital: sincroniza el portapapeles con el sistema
opt.clipboard = "unnamedplus"

-- Mejora la experiencia visual al pegar
opt.mouse = "a" -- Habilita el mouse en todos los modos

-- Al final de custom/options.lua
vim.filetype.add {
  extension = {
    kdl = "kdl",
  },
}
