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

-- Source - https://stackoverflow.com/a
-- Posted by hookenz, modified by community. See post 'Timeline' for change history
-- Retrieved 2025-11-28, License - CC BY-SA 4.0
local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

local function find_math_delimiters(line, col)
	local open = "\\("
	local close = "\\)"
	return line:find(open, col, true)
end

local attributers = {
	["="] = true,
	["\\leq"] = true,
	["\\geq"] = true,
	["<"] = true,
	[">"] = true,
	["\\approx"] = true,
	["\\propto"] = true,
}

local function last_before(s, pattern, idx)
	local last = nil
	local start = 1
	while true do
		local i = s:find(pattern, start, true)
		if not i or i >= idx then
			return last
		end
		last = i
		start = i + 1
	end
end

local function last_before_list(s, pattern_list, idx)
	local max = 0
	for _, pattern in ipairs(pattern_list) do
		local last = last_before(s, pattern, idx)
		if last and last > max then
			max = last
		end
	end
	return max
end

local function find_attributer_bool(s)
	local depth = 0
	local equal_list = {}

	for i = 1, #s do
		local c = s:sub(i, i)
		local c_long = s:sub(i, math.min(#s, i + 3))
		local c_extra = s:sub(i, math.min(#s, i + 6))
		local c_before = s:sub(math.max(i - 1, 1), i)

		if c_before == "\\(" or c_before == "\\)" then
		elseif c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = math.max(depth - 1, 0)
		elseif attributers[c_extra] then
			if depth == 0 then
				return true
			end
		elseif attributers[c_long] then
			if depth == 0 then
				return true
			end
		elseif attributers[c] then
			if depth == 0 then
				return true
			end
		end
	end

	return false
end

local function find_attributer(s)
	local depth = 0
	local equal_list = {}

	for i = 1, #s do
		local c = s:sub(i, i)
		local c_long = s:sub(i, math.min(#s, i + 3))
		local c_extra = s:sub(i, math.min(#s, i + 6))
		local c_before = s:sub(math.max(i - 1, 1), i)

		if c_before == "\\(" or c_before == "\\)" then
		elseif c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = math.max(depth - 1, 0)
		elseif attributers[c_extra] then
			if depth == 0 then
				table.insert(equal_list, { i, i + 6 })
			end
		elseif attributers[c_long] then
			if depth == 0 then
				table.insert(equal_list, { i, i + 3 })
			end
		elseif attributers[c] then
			if depth == 0 then
				table.insert(equal_list, { i, i })
			end
		end
	end

	return equal_list
end

local function find_delimiter_containing_attributer(s, start, open, close)
	local open_idx = 1
	local close_idx
	local has_attributer

	while not has_attributer and open_idx do
		open_idx = s:find(open, start, true)
		if open_idx then
			open_idx = open_idx + #open
			_, close_idx = s:find(close, open_idx, true)
			if close_idx then
				close_idx = close_idx - #close
				has_attributer = find_attributer_bool(s:sub(open_idx, close_idx))
				start = close_idx
			end
		end
	end
	return open_idx, close_idx
end

local function find_two_lower_two_upper(pairs_list, x)
	local lower1, lower2 = nil, nil -- largest and 2nd largest < x
	local upper1, upper2 = nil, nil -- smallest and 2nd smallest > x

	for _, pair in ipairs(pairs_list) do
		local a = pair[1]

		-- LOWER numbers
		if a <= x then
			if (not lower1) or (a > lower1[1]) then
				lower2 = lower1
				lower1 = pair
			elseif (not lower2) or (a > lower2[1]) then
				lower2 = pair
			end
		end

		-- UPPER numbers
		if a > x then
			if (not upper1) or (a < upper1[1]) then
				upper2 = upper1
				upper1 = pair
			elseif (not upper2) or (a < upper2[1]) then
				upper2 = pair
			end
		end
	end

	return lower1, lower2, upper1, upper2
end

local function in_multiline_math()
	return (vim.fn["vimtex#syntax#in"]("texMathZoneEnv") == 1 and vim.fn["vimtex#syntax#in"]("texCmdMathEnv") == 0)
		or (vim.fn["vimtex#syntax#in"]("texMathZoneLD") == 1 and vim.fn["vimtex#syntax#in"]("texMathDelimZoneLD") == 0)
		or (vim.fn["vimtex#syntax#in"]("texMathZoneTD") == 1 and vim.fn["vimtex#syntax#in"]("texMathDelimZoneTD") == 0)
end

local function in_math_zone()
	return vim.fn["vimtex#syntax#in_mathzone"]() == 1
		or vim.fn["vimtex#syntax#in"]("texMathDelimZoneLI") == 1
		or vim.fn["vimtex#syntax#in"]("texMathDelimZoneTI") == 1
end

function SelectLatexValue(after, around)
	-- Get current line text and cursor column number
	local line = vim.api.nvim_get_current_line()
	local col = vim.fn.col(".")

	-- Is in math zone and is in multiline math bools
	local inside_math_zone = in_math_zone()
	local inside_multiline_math = in_multiline_math()

	-- Start point to look for delimiters/attributers
	local start_search_col
	if inside_multiline_math then
		start_search_col = 0
	elseif inside_math_zone then
		start_search_col = last_before_list(line, { "\\(", "$" }, col)
		if start_search_col == nil then
			return
		end
	else
		start_search_col = col
	end

	-- Locate start and end the next math zone with a unenclosed delimiter inside
	local open_math, close_math, math_part
	if not inside_multiline_math then
		open_math, close_math = find_delimiter_containing_attributer(line, start_search_col, "\\(", "\\)")
		if open_math == nil or close_math == nil then
			return
		end
		math_part = line:sub(open_math, close_math)
	else
		open_math, close_math = 1, #line
		math_part = line
	end

	--------------------------------------------------------
	--                4 POINTS OF INTEREST                --
	--                                                    --
	--    * Simple case                                   --
	--    \(a + b \leq&\ 3 + b + f(x)\)                   --
	--      ^    ^      ^           ^                     --
	--                                                    --
	--    * Multiple attributers                          --
	--                          cursor here |             --
	--    \(a + b \leq c + d + \int x dx = x^2 = e^x\)    --
	--                ^                 ^ ^   ^           --
	--                                                    --
	--------------------------------------------------------
	-- Cursor column relative to math part
	local relative_col = col - open_math

	-- Get all attributer positions
	local attributers_list = find_attributer(math_part)
	-- print(open_math, dump(attributers_list))

	-- Two attributers before cursor, two after
	local lower1, lower2, upper1, upper2 = find_two_lower_two_upper(attributers_list, relative_col)
	-- print(dump(lower1), dump(lower2), dump(upper1), dump(upper2))

	-- Position of the attributer in the middle of the selection
	local middle_attributer, bottom, top
	if lower1 ~= nil and upper1 == nil then
		middle_attributer = lower1
		top = #math_part
		if lower2 == nil then
			bottom = 1
		else
			bottom = lower2[2] + 1
		end
	elseif lower1 == nil and upper1 ~= nil then
		middle_attributer = upper1
		bottom = 1
		if upper2 == nil then
			top = #math_part
		else
			top = upper2[1] - 1
		end
	elseif lower1 ~= nil and upper1 ~= nil then
		middle_attributer = lower1
		top = upper1[1] - 1
		if lower2 == nil then
			bottom = 1
		else
			bottom = lower2[2] + 1
		end
	end

	local point1, point2, point3, point4 = bottom, middle_attributer[1] - 1, middle_attributer[2] + 1, top

	-- Change to absolute coordinates
	point1 = point1 + open_math - 1
	point2 = point2 + open_math - 1
	point3 = point3 + open_math - 1
	point4 = point4 + open_math - 1

	-- Remove trailing spaces
	-- print(point1, line:sub(point1, point1), line:sub(point1, point1) == " ")
	while line:sub(point1, point1) == " " do
		point1 = point1 + 1
	end
	while line:sub(point2, point2) == " " do
		point2 = point2 - 1
	end
	while line:sub(point3, point3) == " " do
		point3 = point3 + 1
	end
	while line:sub(point4, point4) == " " do
		point4 = point4 - 1
	end

	-- Remove \\ in multiline math if not using around
	if not around and line:sub(point4 - 1, point4) == "\\\\" then
		point4 = point4 - 2
	end
	while line:sub(point4, point4) == " " do
		point4 = point4 - 1
	end

	-- Remove & and \ when not using around
	while line:sub(point3, point3) == "&" or line:sub(point3, point3) == "\\" or line:sub(point3, point3) == " " do
		point3 = point3 + 1
	end
	while line:sub(point2, point2) == "&" or line:sub(point2, point2) == "\\" or line:sub(point2, point2) == " " do
		point2 = point2 - 1
	end

	local left, right
	if not around then
		if after then
			left = point3
			right = point4
		else
			left = point1
			right = point2
		end
	else
		if after then
			left = point2 + 1
			right = point4
		else
			left = point1
			right = point3 - 1
		end
	end

	if left > right then
		return
	end

	vim.fn.setpos("'<", { 0, vim.fn.line("."), left, 0 })
	vim.fn.setpos("'>", { 0, vim.fn.line("."), right, 0 })
	vim.cmd("normal! gv")
end
