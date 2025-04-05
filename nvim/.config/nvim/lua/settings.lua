vim.opt.pumheight = 5 -- Makes popup menu smaller
vim.opt.pumblend = 15 -- Popup menu transparency
-- Disable hover documentation globally
vim.lsp.handlers["textDocument/hover"] = function() end

local cmp = require("cmp")

cmp.setup({
	view = {
		docs = {
			auto_open = false,
		},
	},
	mapping = {
		["<C-g>"] = function()
			if cmp.visible_docs() then
				cmp.close_docs()
			else
				cmp.open_docs()
			end
		end,
	},
})
-- set linebreak
vim.opt.linebreak = true
