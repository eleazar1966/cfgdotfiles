require "nvchad.mappings"
local map = vim.keymap.set

-- Ejecución rápida (Limpia terminal antes de correr)
map("n", "<leader>py", "<cmd>set splitbelow | sp | term clear && python3 % <CR>", { desc = "Ejecutar Python" })
map("n", "<leader>sh", "<cmd>set splitbelow | sp | term clear && bash % <CR>", { desc = "Ejecutar Bash" })

-- Comentar (Soporte para múltiples terminales)
map({ "n", "v" }, "<C-_>", "gc", { remap = true, desc = "Comentar" })
map({ "n", "v" }, "<C-/>", "gc", { remap = true, desc = "Comentar" })

-- Navegación y UI
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "Alternar Relativos" })
map("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', { desc = "Spectre" })
map({ "n", "t" }, "<leader>tx", "<C-\\><C-n><cmd>bd!<CR>", { desc = "Cerrar Buffer/Term" })
