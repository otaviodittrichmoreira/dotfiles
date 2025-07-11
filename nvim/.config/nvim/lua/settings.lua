vim.opt.pumheight = 5 -- Makes popup menu smaller
vim.opt.pumblend = 15 -- Popup menu transparency
-- Disable hover documentation globally
vim.lsp.handlers["textDocument/hover"] = function() end

-- File handling
vim.opt.backup = false -- Don't create backup files
vim.opt.writebackup = false -- Don't create backup before writing
vim.opt.swapfile = false -- Don't create swap files
vim.opt.undofile = true -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300 -- Faster completion
vim.opt.timeoutlen = 500 -- Key timeout duration
vim.opt.ttimeoutlen = 0 -- Key code timeout
vim.opt.autoread = true -- Auto reload files changed outside vim
vim.opt.autowrite = false

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

-- Disable copilot on .tex files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.cmd("Copilot disable")
	end,
})
