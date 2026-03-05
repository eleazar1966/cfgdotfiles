-- filepath: custom/chadrc.lua
---@type ChadrcConfig
local M = {}

M.ui = {
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
        elseif total_line > 500 then
          color = "%#St_LspInfoBg#"
        end

        return color .. "  " .. line .. ":" .. col .. " / " .. total_line .. " "
      end,
    },
  },
}

M.base46 = { theme = "gatekeeper" }

return M
