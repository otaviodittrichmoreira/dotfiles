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
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true -- Use spaces instead of tabs

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

-- Open binary files
vim.api.nvim_create_autocmd("BufReadCmd", {
	pattern = "*.pdf",
	callback = function()
		local filename = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
		vim.cmd("silent !zathura " .. filename .. " &")
		vim.cmd("let tobedeleted = bufnr('%') | b# | exe \"bd! \" . tobedeleted")
	end,
})

vim.api.nvim_create_autocmd("BufReadCmd", {
	pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" },
	callback = function()
		local filename = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
		vim.cmd("silent !/home/otavio/bin/feh-viewer.sh  " .. filename .. " &")
		vim.cmd("let tobedeleted = bufnr('%') | b# | exe \"bd! \" . tobedeleted")
	end,
})

-- Define 'inside value' (iv) and 'around value' (av) text objects for LaTeX equations
vim.api.nvim_set_keymap("x", "iv", [[:<C-u>lua SelectLatexValue(true, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "iv", [[:<C-u>lua SelectLatexValue(true, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "av", [[:<C-u>lua SelectLatexValue(true, true)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "av", [[:<C-u>lua SelectLatexValue(true, true)<CR>]], { noremap = true, silent = true })

-- Define 'inside value' (in) and 'around value' (an) text objects for LaTeX equations
vim.api.nvim_set_keymap("x", "in", [[:<C-u>lua SelectLatexValue(false, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "in", [[:<C-u>lua SelectLatexValue(false, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "an", [[:<C-u>lua SelectLatexValue(false, true)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "an", [[:<C-u>lua SelectLatexValue(false, true)<CR>]], { noremap = true, silent = true })

function Find_unenclosed_equal(s)
	local depth = 0, 0

	for i = 1, #s do
		local c = s:sub(i, i)

		if c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = math.max(depth - 1, 0)
		elseif c == "=" then
			if depth == 0 then
				return i
			end
		end
	end

	return nil -- no unenclosed '=' found
end

function SafeMin(...)
	local args = { ... }
	local min_val = nil

	for _, v in ipairs(args) do
		if v ~= nil then
			if min_val == nil or v < min_val then
				min_val = v
			end
		end
	end
	return min_val
end

function SafeMax(...)
	local args = { ... }
	local max_val = nil

	for _, v in ipairs(args) do
		if v ~= nil then
			if max_val == nil or v > max_val then
				max_val = v
			end
		end
	end
	return max_val
end

function SelectLatexValue(after, around)
	local line = vim.api.nvim_get_current_line()
	local col = vim.fn.col(".")

	local last = SafeMax(Find_unenclosed_equal(line), line:find("&"))
	if line:sub(last + 1, last + 1) == "\\" then
		last = last + 1
	end
	if line:sub(last + 1, last + 1) == " " then
		last = last + 1
	end

	local first = SafeMin(Find_unenclosed_equal(line), line:find("&"))

	local eq_pos
	if (after and not around) or (not after and around) then
		eq_pos = last
	else
		eq_pos = first
	end

	if after and col < eq_pos then
		-- If cursor is before '=', move to after '='
		vim.fn.cursor(vim.fn.line("."), eq_pos + 1)
	elseif not after and col > eq_pos then
		vim.fn.cursor(vim.fn.line("."), eq_pos - 1)
	end

	local rhs = line:sub(eq_pos + 1)
	local s_col = eq_pos
	if not around then
		if after then
			s_col = eq_pos + 1
		else
			s_col = eq_pos - 1
		end
	end

	while after and line:sub(s_col, s_col) == " " do
		s_col = s_col + 1
	end

	if line:sub(1, s_col):match("^%s*$") == nil then
		while not after and line:sub(s_col, s_col) == " " do
			s_col = s_col - 1
		end
	end

	local e_col
	if after then
		e_col = #line
		if not around then
			local break_line_col = line:find("\\\\")
			if break_line_col then
				e_col = break_line_col - 1
			end
			local _, last_non_space = line:find(".*%S")
			if last_non_space then
				e_col = math.min(e_col, last_non_space)
			end
		end
	else
		e_col = SafeMin(line:find("%S"), s_col)
	end

	print("s_col =", s_col)
	print("e_col =", e_col)
	vim.fn.setpos("'<", { 0, vim.fn.line("."), s_col, 0 })
	vim.fn.setpos("'>", { 0, vim.fn.line("."), e_col, 0 })
	vim.cmd("normal! gv")
end

-- In visual mode, pressing : will prefill the command line
vim.api.nvim_set_keymap("v", ":", [[:s/\%V]], { noremap = true, silent = false })
