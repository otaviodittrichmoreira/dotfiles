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
vim.opt.tabstop = 4 -- Number of spaces for a tab

-- Spell Check for .tex files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.opt.spell = true
		vim.opt.spelllang = "en_us"
	end,
})

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

-- Disable copilot
vim.cmd("Copilot disable")

-- -- Disable copilot on .tex files
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = "tex",
-- 	callback = function()
-- 		vim.cmd("Copilot disable")
-- 	end,
-- })

-- Wrap REPL terminal lines
vim.api.nvim_create_autocmd("FileType", {
	pattern = "dap-repl",
	callback = function()
		vim.opt_local.wrap = true -- enable line wrap
		vim.opt_local.linebreak = true -- break lines at word boundaries
		vim.opt_local.number = false -- disable line numbers in REPL
		vim.opt_local.relativenumber = false
	end,
})

-- Use python3 to run the current file with :make
vim.api.nvim_create_autocmd("FileType", {
	pattern = "r",
	callback = function()
		vim.bo.makeprg = "Rscript %"
	end,
})

-- Use python3 to run the current file with :make
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.bo.makeprg = "python3 %"
	end,
})

-- Remove <Space>, keymap from r
vim.api.nvim_create_autocmd("FileType", {
	pattern = "r",
	callback = function(args)
		-- make sure we’re in insert mode keymaps
		pcall(vim.keymap.del, "i", "<Space>,", { buffer = args.buf })
		pcall(vim.keymap.del, "n", "<Space>m", { buffer = args.buf })
	end,
})
