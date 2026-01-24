require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Mapeos para el Debugger (DAP)
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "DAP Alternar Breakpoint" })
map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "DAP Iniciar/Continuar" })
map("n", "<leader>dx", function()
  require("dap").terminate()
end, { desc = "DAP Detener" })
map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "DAP Entrar (Step Into)" })
map("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "DAP Saltar (Step Over)" })
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "DAP Alternar Interfaz (UI)" })
