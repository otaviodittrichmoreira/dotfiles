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
		local c_before = s:sub(math.max(i - 1, 1), i)

		if c_before == "\\(" or c_before == "\\)" then
		elseif c == "(" or c == "[" then
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

function FindMathDelimiters(line, col)
	local has_equal_between = false
	local open = col
	local close = col
	local pos = col
	local iter = 1
	while not has_equal_between do
		close = line:sub(pos, #line):find("\\)")
		if close then
			close = close + pos
			open = line:sub(1, close):match(".*()\\%(")
		else
			return 1, #line
		end
		if open and close then
			has_equal_between = line:sub(open, close):find("=")
			if not has_equal_between then
				pos = close + 1
			end
		else
			return 1, #line
		end
		iter = iter + 1
		if iter == 200 then
			return 1, #line
		end
	end
	if open then
		open = open + 2
	else
		open = 1
	end
	if close then
		close = close - 2
	else
		close = #line
	end
	return open, close
end

function SelectLatexValue(after, around)
	-- Get current line text and cursor column number
	local line = vim.api.nvim_get_current_line()
	local col = vim.fn.col(".")

	-- find next \( \) that contains an = sign inside it
	local open, close = FindMathDelimiters(line, col)

	-- Change line to be only what's inside math mode
	-- Obs: This changes the relative position to the subline. Has to add open to position to get absolute position back
	local original_line = line
	line = line:sub(open, close)

	-- Find equal sign in line
	local real_eq_pos = Find_unenclosed_equal(line)

	-- Find position of last character attached to = ( =& or =&\ )
	local last = SafeMax(real_eq_pos, line:find("&"))
	if not last then
		return
	end
	if line:sub(last + 1, last + 1) == "\\" then
		last = last + 1
	end
	if line:sub(last + 1, last + 1) == " " then
		last = last + 1
	end

	-- Find position of first character attached to =
	local first = SafeMin(real_eq_pos, line:find("&"))

	-- Define reference for border of selection
	local eq_pos
	if (after and not around) or (not after and around) then
		eq_pos = last
	else
		eq_pos = first
	end

	-- Change to absolute position
	eq_pos = eq_pos + open - 1

	-- Move cursor to the equal sign
	if after and col < eq_pos then
		vim.fn.cursor(vim.fn.line("."), eq_pos + 1)
	elseif not after and col > eq_pos then
		vim.fn.cursor(vim.fn.line("."), eq_pos - 1)
	end

	-- Actuall border selection
	local s_col = eq_pos
	if not around then
		if after then
			s_col = eq_pos + 1
		else
			s_col = eq_pos - 1
		end
	end

	if line:sub(1, s_col):match("^%s*$") == nil then
		if not after then
			while line:sub(s_col, s_col) == " " do
				s_col = s_col - 1
			end
		end
	end

	local subline = line:sub(open, close)
	local e_col
	if after then
		e_col = close
		if not around then
			local break_line_col = subline:find("\\\\")
			if break_line_col then
				e_col = break_line_col - 1
			end
			local _, last_non_space = subline:sub(1, e_col):find(".*%S")
			if last_non_space then
				e_col = math.min(e_col, last_non_space) + open - 1
			end
		end
	else
		e_col = SafeMin(SafeMax(line:find("%S"), open), s_col)
	end

	-- Remove spaces from selection
	if not around then
		if after then
			while original_line:sub(s_col, s_col) == " " do
				s_col = s_col + 1
			end
		else
			while original_line:sub(s_col, s_col) == " " do
				s_col = s_col - 1
			end
		end
	end

	vim.fn.setpos("'<", { 0, vim.fn.line("."), s_col, 0 })
	vim.fn.setpos("'>", { 0, vim.fn.line("."), e_col, 0 })
	vim.cmd("normal! gv")
end
