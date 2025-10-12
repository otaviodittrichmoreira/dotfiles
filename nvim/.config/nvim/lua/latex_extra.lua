-- Spell Check for .tex files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.opt.spell = true
		vim.opt.spelllang = "en_us"
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
	local symbols = {
		["="] = true,
		["\\leq"] = true,
		["\\geq"] = true,
		["<"] = true,
		[">"] = true,
	}
	local depth = 0

	for i = 1, #s do
		local c = s:sub(i, i)
		local c_long = s:sub(i, math.min(#s, i + 3))

		if c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = math.max(depth - 1, 0)
		elseif symbols[c] or symbols[c_long] then
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
			local _, last_non_space = line:sub(1, e_col):find(".*%S")
			if last_non_space then
				e_col = math.min(e_col, last_non_space)
			end
		end
	else
		e_col = SafeMin(line:find("%S"), s_col)
	end

	vim.fn.setpos("'<", { 0, vim.fn.line("."), s_col, 0 })
	vim.fn.setpos("'>", { 0, vim.fn.line("."), e_col, 0 })
	vim.cmd("normal! gv")
end
