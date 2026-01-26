require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- Comentar con Ctrl + / (o Ctrl + _)
map("n", "<C-_>", "gcc", { remap = true, desc = "Comentar línea" })
map("v", "<C-_>", "gc", { remap = true, desc = "Comentar selección" })

-- En algunos terminales el mapeo es <C-/>
map("n", "<C-/>", "gcc", { remap = true, desc = "Comentar línea" })
map("v", "<C-/>", "gc", { remap = true, desc = "Comentar selección" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Atajo para Spectre (Buscar y Reemplazar en todo el proyecto)
map("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', {
  desc = "Spectre: Buscar y reemplazar global",
})

-- Opcional: Buscar la palabra bajo el cursor en todo el proyecto
map("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
  desc = "Spectre: Buscar palabra actual",
})

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

-- Ejecutar archivo Python actual en una terminal horizontal
map("n", "<leader>py", "<cmd>set splitbelow | sp | term python3 % <CR>", { desc = "Ejecutar Python" })

-- Ejecutar archivo Bash actual
map("n", "<leader>sh", "<cmd>set splitbelow | sp | term bash % <CR>", { desc = "Ejecutar Bash" })

-- Navegar entre ventanas (incluso terminales) con Alt + h/j/k/l
map("t", "<A-h>", "<C-\\><C-n><C-w>h")
map("t", "<A-j>", "<C-\\><C-n><C-w>j")
map("t", "<A-k>", "<C-\\><C-n><C-w>k")
map("t", "<A-l>", "<C-\\><C-n><C-w>l")
map("n", "<A-h>", "<C-w>h")
map("n", "<A-j>", "<C-w>j")
map("n", "<A-k>", "<C-w>k")
map("n", "<A-l>", "<C-w>l")

-- MANTENER ESTE (al final de mappings.lua)
map({ "i", "s" }, "<Tab>", function()
  if require("luasnip").expand_or_jumpable() then
    require("luasnip").expand_or_jump()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end, { silent = true })

-- Terminal Horizontal (Abajo, 30% altura)
map("n", "<leader>th", function()
  vim.cmd "split | term"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.3))

  -- Auto-cierre al finalizar el proceso
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      vim.cmd "bdelete"
    end,
  })
end, { desc = "Terminal abajo 30% (auto-close)" })

-- Terminal Vertical (Derecha, 30% ancho)
map("n", "<leader>tv", function()
  vim.cmd "vsplit | term"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * 0.3))

  -- Auto-cierre al finalizar el proceso
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      vim.cmd "bdelete"
    end,
  })
end, { desc = "Terminal derecha 30% (auto-close)" })

-- Atajo para alternar números relativos (líder + n + r)
map("n", "<leader>nr", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Alternar números relativos" })

-- Alternar números relativos
map("n", "<leader>rn", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Alternar números relativos" })

-- Alternar resaltado de línea actual
map("n", "<leader>cl", function()
  vim.opt.cursorline = not vim.opt.cursorline:get()
end, { desc = "Alternar resaltado de línea" })

-- Ejecutar Python con limpieza previa
map("n", "<leader>py", "<cmd>set splitbelow | sp | term clear && python3 % <CR>", { desc = "Ejecutar Python (Limpio)" })

-- Ejecutar Bash con limpieza previa
map("n", "<leader>sh", "<cmd>set splitbelow | sp | term clear && bash % <CR>", { desc = "Ejecutar Bash (Limpio)" })

-- Cerrar la ventana o terminal actual a la fuerza
map({ "n", "t" }, "<leader>tx", "<C-\\><C-n><cmd>bd!<CR>", { desc = "Cerrar Terminal/Buffer forzado" })
